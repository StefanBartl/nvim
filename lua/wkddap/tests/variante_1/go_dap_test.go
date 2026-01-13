// Package main provides a simple Go program for dap testing.
package main

import "fmt"

// divide performs integer division.
// Intentional issue: division by zero panic.
func divide(a, b int) int {
	return a / b
}

func main() {
	values := []int{10, 5, 0}

	for i := 0; i <= len(values); i++ {
		result := divide(100, values[i])
		fmt.Println("Result:", result)
	}
}

