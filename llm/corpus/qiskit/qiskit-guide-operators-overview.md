---
source: https://docs.quantum.ibm.com/guides/operators-overview
fetched: 2026-08-21
---

Overview of operator classes | IBM Quantum Documentation

-

-

-

-

-

-

-

-

-

-

-

-

-

-

-

##

# Overview of operator classes

-

The code on this page was developed using the following requirements.
We recommend using these versions or newer.

```
qiskit[all]~=2.5.1

```

In Qiskit, quantum operators are represented using classes from the `quantum_info` module. The most important operator class is `SparsePauliOp`, which represents a general quantum operator as a linear combination of Pauli strings. `SparsePauliOp` is the class most commonly used to represent quantum observables. The rest of this page explains how to use `SparsePauliOp` and other operator classes.

```
import numpy as npfrom qiskit.quantum_info.operators import Operator, Pauli, SparsePauliOp
```

## SparsePauliOp

The `SparsePauliOp` class represents a linear combination of Pauli strings. There are several ways to initialize a `SparsePauliOp`, but the most flexible way is to use the `from_sparse_list` method, as demonstrated in the following code cell. The `from_sparse_list` accepts a list of `(pauli_string, qubit_indices, coefficient)` triplets.

```
op1 = SparsePauliOp.from_sparse_list(    [("ZX", [1, 4], 1.0), ("YY", [0, 3], -1 + 1j)], num_qubits=5)op1
```

Output:

```
SparsePauliOp(['XIIZI', 'IYIIY'],
              coeffs=[ 1.+0.j, -1.+1.j])

```

`SparsePauliOp` supports arithmetic operations, as demonstrated in the following code cell.

```
op2 = SparsePauliOp.from_sparse_list(    [("XXZ", [0, 1, 4], 1 + 2j), ("ZZ", [1, 2], -1 + 1j)], num_qubits=5)# Additionprint("op1 + op2:")print(op1 + op2)print()# Multiplication by a scalarprint("2 * op1:")print(2 * op1)print()# Operator multiplication (composition)print("op1 @ op2:")print(op1 @ op2)print()# Tensor productprint("op1.tensor(op2):")print(op1.tensor(op2))
```

Output:

```
op1 + op2:
SparsePauliOp(['XIIZI', 'IYIIY', 'ZIIXX', 'IIZZI'],
              coeffs=[ 1.+0.j, -1.+1.j,  1.+2.j, -1.+1.j])

2 * op1:
SparsePauliOp(['XIIZI', 'IYIIY'],
              coeffs=[ 2.+0.j, -2.+2.j])

op1 @ op2:
SparsePauliOp(['YIIYX', 'XIZII', 'ZYIXZ', 'IYZZY'],
              coeffs=[ 1.+2.j, -1.+1.j, -1.+3.j,  0.-2.j])

op1.tensor(op2):
SparsePauliOp(['XIIZIZIIXX', 'XIIZIIIZZI', 'IYIIYZIIXX', 'IYIIYIIZZI'],
              coeffs=[ 1.+2.j, -1.+1.j, -3.-1.j,  0.-2.j])

```

## Pauli

The `Pauli` class represents a single Pauli string with an optional phase coefficient from the set {+1,i,−1,−i}\set{+1, i, -1, -i}{+1,i,−1,−i}. A `Pauli` can be initialized by passing a string of characters from the set `{"I", "X", "Y", "Z"}`, optionally prefixed by one of `{"", "i", "-", "-i"}` to represent the phase coefficient.

```
op1 = Pauli("iXX")op1
```

Output:

```
Pauli('iXX')

```

The following code cell demonstrates the use of some attributes and methods.

```
print(f"Dimension of {op1}: {op1.dim}")print(f"Phase of {op1}: {op1.phase}")print(f"Matrix representation of {op1}: \n {op1.to_matrix()}")
```

Output:

```
Dimension of iXX: (4, 4)
Phase of iXX: 3
Matrix representation of iXX:
 [[0.+0.j 0.+0.j 0.+0.j 0.+1.j]
 [0.+0.j 0.+0.j 0.+1.j 0.+0.j]
 [0.+0.j 0.+1.j 0.+0.j 0.+0.j]
 [0.+1.j 0.+0.j 0.+0.j 0.+0.j]]

```

`Pauli` objects possess a number of other methods to manipulate the operators such as determining its adjoint, whether it (anti)commutes with another `Pauli`, and computing the dot product with another `Pauli`. Refer to the API documentation for more info.

## Operator

The `Operator` class represents a general linear operator. Unlike `SparsePauliOp`, `Operator` stores the linear operator as a dense matrix. Because the memory required to store a dense matrix scales exponentially with the number of qubits, the `Operator` class is only suitable for use with a small number of qubits.

You can initialize an `Operator` by directly passing a Numpy array storing the matrix of the operator. For example, the following code cell creates a two-qubit Pauli XX operator:

```
XX = Operator(    np.array(        [            [0, 0, 0, 1],            [0, 0, 1, 0],            [0, 1, 0, 0],            [1, 0, 0, 0],        ]    ))XX
```

Output:

```
Operator([[0.+0.j, 0.+0.j, 0.+0.j, 1.+0.j],
          [0.+0.j, 0.+0.j, 1.+0.j, 0.+0.j],
          [0.+0.j, 1.+0.j, 0.+0.j, 0.+0.j],
          [1.+0.j, 0.+0.j, 0.+0.j, 0.+0.j]],
         input_dims=(2, 2), output_dims=(2, 2))

```

The operator object stores the underlying matrix, and the input and output dimension of subsystems.

- `data`: To access the underlying Numpy array, you can use the `Operator.data` property.

- `dims`: To return the total input and output dimension of the operator, you can use the `Operator.dim` property. Note: the output is returned as a tuple`(input_dim, output_dim)`, which is the reverse of the shape of the underlying matrix.

```
XX.data
```

Output:

```
array([[0.+0.j, 0.+0.j, 0.+0.j, 1.+0.j],
       [0.+0.j, 0.+0.j, 1.+0.j, 0.+0.j],
       [0.+0.j, 1.+0.j, 0.+0.j, 0.+0.j],
       [1.+0.j, 0.+0.j, 0.+0.j, 0.+0.j]])

```

```
input_dim, output_dim = XX.diminput_dim, output_dim
```

Output:

```
(4, 4)

```

The operator class also keeps track of subsystem dimensions, which can be used for composing operators together. These can be accessed using the `input_dims` and `output_dims` functions.

For 2N2^N2N by 2M2^M2M operators, the input and output dimensions are automatically assumed to be M-qubit and N-qubit:

```
op = Operator(np.random.rand(2**1, 2**2))print("Input dimensions:", op.input_dims())print("Output dimensions:", op.output_dims())
```

Output:

```
Input dimensions: (2, 2)
Output dimensions: (2,)

```

If the input matrix is not divisible into qubit subsystems, then it will be stored as a single-qubit operator. For example, for a 6×66\times66×6 matrix:

```
op = Operator(np.random.rand(6, 6))print("Input dimensions:", op.input_dims())print("Output dimensions:", op.output_dims())
```

Output:

```
Input dimensions: (6,)
Output dimensions: (6,)

```

The input and output dimension can also be manually specified when initializing a new operator:

```
# Force input dimension to be (4,) rather than (2, 2)op = Operator(np.random.rand(2**1, 2**2), input_dims=[4])print("Input dimensions:", op.input_dims())print("Output dimensions:", op.output_dims())
```

Output:

```
Input dimensions: (4,)
Output dimensions: (2,)

```

```
# Specify system is a qubit and qutritop = Operator(np.random.rand(6, 6), input_dims=[2, 3], output_dims=[2, 3])print("Input dimensions:", op.input_dims())print("Output dimensions:", op.output_dims())
```

Output:

```
Input dimensions: (2, 3)
Output dimensions: (2, 3)

```

You can also extract just the input or output dimensions of a subset of subsystems using the `input_dims` and `output_dims` functions:

```
print("Dimension of input system 0:", op.input_dims([0]))print("Dimension of input system 1:", op.input_dims([1]))
```

Output:

```
Dimension of input system 0: (2,)
Dimension of input system 1: (3,)

```

## Next steps

Recommendations

- Learn how to specify observables in the Pauli basis.

- See an example of using operators in the Combine error mitigation options with the Estimator primitive tutorial.

- Read more in-depth coverage of the Operator class.

- Explore the Operator API reference.

Was this page helpful?

Report a bug, typo, or request content on GitHub.

On this page

- SparsePauliOp

- Pauli

- Operator

- Next steps

Download notebook

Was this page helpful?

Report a bug, typo, or request content on GitHub.

© IBM Corp., 2017-2026

-

-

-

-

-

-

Open search dialog
