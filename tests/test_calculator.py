import unittest
from src.calculator import Calculator

class TestCalculator(unittest.TestCase):

    def setUp(self):
        """Set up a Calculator instance before each test."""
        self.calculator = Calculator()

    def test_add(self):
        """Test the add method."""
        self.assertEqual(self.calculator.add(2, 3), 5)
        self.assertEqual(self.calculator.add(-1, 1), 0)
        self.assertEqual(self.calculator.add(-1, -1), -2)

    def test_subtract(self):
        """Test the subtract method."""
        self.assertEqual(self.calculator.subtract(3, 2), 1)
        self.assertEqual(self.calculator.subtract(2, 3), -1)
        self.assertEqual(self.calculator.subtract(-1, -1), 0)

    def test_multiply(self):
        """Test the multiply method."""
        self.assertEqual(self.calculator.multiply(2, 3), 6)
        self.assertEqual(self.calculator.multiply(-1, 3), -3)
        self.assertEqual(self.calculator.multiply(-1, -1), 1)

    def test_divide(self):
        """Test the divide method."""
        self.assertEqual(self.calculator.divide(6, 3), 2)
        self.assertEqual(self.calculator.divide(-6, 3), -2)
        self.assertEqual(self.calculator.divide(-6, -3), 2)
        self.assertEqual(self.calculator.divide(5, 2), 2.5)

    def test_divide_by_zero(self):
        """Test division by zero."""
        with self.assertRaisesRegex(ValueError, "Error: Division by zero is not allowed."):
            self.calculator.divide(5, 0)

    def test_power(self):
        """Test the power method."""
        self.assertEqual(self.calculator.power(2, 3), 8)  # 2^3 = 8
        self.assertEqual(self.calculator.power(5, 0), 1)  # 5^0 = 1
        self.assertEqual(self.calculator.power(3, 1), 3)  # 3^1 = 3
        self.assertEqual(self.calculator.power(2, -1), 0.5) # 2^-1 = 0.5
        self.assertEqual(self.calculator.power(4, 0.5), 2) # 4^0.5 = 2
        # Test with a negative base
        self.assertEqual(self.calculator.power(-2, 2), 4) # (-2)^2 = 4
        self.assertEqual(self.calculator.power(-2, 3), -8) # (-2)^3 = -8


if __name__ == '__main__':
    unittest.main()
