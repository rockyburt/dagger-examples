import os

from quart import Quart

app = Quart(os.environ["APP_NAME"])


@app.route("/")
async def hello():
    return "hello"


def main():
    app.run(host="0.0.0.0")


if __name__ == "__main__":
    main()
