import asyncio
import unittest

import app


class TestAll(unittest.TestCase):
    def test_it(self):
        val = asyncio.run(app.hello())
        self.assertEqual(val, "hello")
