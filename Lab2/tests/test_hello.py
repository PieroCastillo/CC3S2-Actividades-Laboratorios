import unittest
from src.hello import greet

class TestGreet(unittest.TestCase):
    def test_greet(self):
        self.assertEqual(greet("Paulette"), "Hello, Paulette!")

if __name__ == "__main__":
    unittest.main()
