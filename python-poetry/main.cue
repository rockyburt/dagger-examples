package pythonpoetry

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"github.com/rockyburt/dagger/python"
	"universe.dagger.io/docker"
	"universe.dagger.io/docker/cli"
)

dagger.#Plan & {
	_src: core.#Source & {
		path: "."
		exclude: ["cue.mod", "README.md", "*.cue", ".build", ".git", ".gitignore"]
	}
    _app: python.#AppConfig & {
        path:		"/pythonapp"
        buildPath:	"/build"
    }

	client: network: "unix:///var/run/docker.sock": connect: dagger.#Socket

    actions: {
		// Setup the initial image for building
        // you can override the default python3.10 image with: `baseImageTag: "public.ecr.aws/docker/library/python:3.9-slim-bullseye"`
		initBuildImage: python.#Image & {}

		// Get python version of poetry source package
		sourceVersion: python.#GetPackageVersionByPoetry & {
			source:     initBuildImage.output
			project:    _src.output
		}

		// Setup the baseImage with a Python virtualenv
		createVirtualenv: python.#CreateVirtualenv & {
			app:        _app
			source:     initBuildImage.output
		}

		// Install Poetry-derived requirements-based dependencies
		installRequirements: python.#InstallPoetryRequirements & {
			app:        _app
			source:     createVirtualenv.output
			project:    _src.output
			name:       sourceVersion.packageName
		}

		// Build the source package as wheel/sdist
		buildSource: python.#BuildPoetrySourcePackage & {
			app:        _app
			source:     installRequirements.output
			project:    _src.output
		}

		// Install the built wheel
		installSource: python.#InstallWheelFile & {
			app:        _app
			source:     buildSource.output
			wheel:      buildSource.export.dist.bdistWheel.path
		}

		// Build destination runnable image
		buildRunnableImage: docker.#Build & {
			steps: [
				docker.#Pull & {
					source: initBuildImage.baseImageTag
				},
				docker.#Copy & {
					contents: installSource.export.app
					dest: _app.path
				},
				docker.#Set & {
                	config: {
						env: {
							"APP_NAME": sourceVersion.packageName
						}
						cmd: ["\(_app.venvDir)/bin/python", "-m", "app"]
					}
            	},				
			]
		}

		// Run the python tests
		runTests: docker.#Run & {
				input: buildRunnableImage.output
				always: true
				workdir: "/test"
				mounts: projectMount: {
						dest:     workdir
						contents: _src.output
				}
				command: {
						name: "\(_app.venvDir)/bin/python"
						args: ["-m", "unittest", "discover", "-s", "tests"]
				}
		}

		// Load image into local docker daemon
		loadIntoDocker: cli.#Load & {
			image: buildRunnableImage.output
			host: client.network."unix:///var/run/docker.sock".connect
			tag: "\(sourceVersion.packageName):dev"
		}
    }
}
