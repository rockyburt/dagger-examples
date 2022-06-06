# Python Poetry Example

Initialize the Dagger project:

```sh
dagger project init
dagger project update github.com/rockyburt/dagger
dagger project update
```

To run the tests contained within the `tests` directory, run this command:

```sh
dagger do runTests
```

To build and run this app within a new docker container:

```sh
dagger do loadIntoDocker
docker run -it --rm python-poetry:dev
```
