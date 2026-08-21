---
source: https://pennylane.ai/qml/demos/tutorial_qubit_rotation
fetched: 2026-08-21
---

Basic tutorial: qubit rotation | PennyLane Demos

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

Install

####

-

-

-

####

-

-

-

-

-

-

-

#### Downloads

- Download Python script

- Download Notebook

- View on GitHub

-

- Demos/

- Getting Started/

-
Basic tutorial: qubit rotation

# Basic tutorial: qubit rotation

Josh Izaac

Published: October 10, 2019.Last updated: April 17, 2026.

To see how PennyLane allows the easy construction and optimization of quantum functions, let’s
consider the simple case of qubit rotation the PennyLane version of the ‘Hello, world!’
example.

The task at hand is to optimize two rotation gates in order to flip a single
qubit from state \(\left|0\right\rangle\) to state \(\left|1\right\rangle.\)

## The quantum circuit

In the qubit rotation example, we wish to implement the following quantum circuit:

Breaking this down step-by-step, we first start with a qubit in the ground state
\(|0\rangle = \begin{bmatrix}1 & 0 \end{bmatrix}^T,\)
and rotate it around the x-axis by applying the gate

\[\begin{split}R_x(\phi_1) = e^{-i \phi_1 \sigma_x /2} =
\begin{bmatrix} \cos \frac{\phi_1}{2} &  -i \sin \frac{\phi_1}{2} \\
               -i \sin \frac{\phi_1}{2} &  \cos \frac{\phi_1}{2}
\end{bmatrix},\end{split}\]

and then around the y-axis via the gate

\[\begin{split}R_y(\phi_2) = e^{-i \phi_2 \sigma_y/2} =
\begin{bmatrix} \cos \frac{\phi_2}{2} &  - \sin \frac{\phi_2}{2} \\
                \sin \frac{\phi_2}{2} &  \cos \frac{\phi_2}{2}
\end{bmatrix}.\end{split}\]

After these operations the qubit is now in the state

\[| \psi \rangle = R_y(\phi_2) R_x(\phi_1) | 0 \rangle.\]

Finally, we measure the expectation value \(\langle \psi \mid \sigma_z \mid \psi \rangle\)
of the Pauli-Z operator

\[\begin{split}\sigma_z =
\begin{bmatrix} 1 &  0 \\
                0 & -1
\end{bmatrix}.\end{split}\]

Using the above to calculate the exact expectation value, we find that

\[\langle \psi \mid \sigma_z \mid \psi \rangle
= \langle 0 \mid R_x(\phi_1)^\dagger R_y(\phi_2)^\dagger \sigma_z  R_y(\phi_2) R_x(\phi_1) \mid 0 \rangle
= \cos(\phi_1)\cos(\phi_2).\]

Depending on the circuit parameters \(\phi_1\) and \(\phi_2,\) the
output expectation lies between \(1\) (if \(\left|\psi\right\rangle = \left|0\right\rangle\))
and \(-1\) (if \(\left|\psi\right\rangle = \left|1\right\rangle\)).

Let’s see how we can easily implement and optimize this circuit using PennyLane.

## Importing PennyLane and NumPy

The first thing we need to do is import PennyLane, as well as the wrapped version
of NumPy provided by Jax.

```
import pennylane as qp
from jax import numpy as np
import jax

```

## Creating a device

Before we can construct our quantum node, we need to initialize a device.

Definition

Any computational object that can apply quantum operations and return a measurement value
is called a quantum device.

In PennyLane, a device could be a hardware device (take a look at our plugins), or a software simulator (such as our high performance simulator PennyLane-Lightning).

Tip

Devices are loaded in PennyLane via the function`device()`

PennyLane supports devices using both the qubit model of quantum computation and devices
using the CV model of quantum computation. In fact, even a hybrid computation containing
both qubit and CV quantum nodes is possible; see the
hybrid computation example for more details.

For this tutorial, we are using the qubit model, so let’s initialize the `'lightning.qubit'` device
provided by PennyLane.

```
dev1 = qp.device("lightning.qubit", wires=1)

```

For all devices, `device()` accepts the following arguments:

-
`name`: the name of the device to be loaded

-
`wires`: the number of subsystems to initialize the device with

Here, as we only require a single qubit for this example, we set `wires=1`.

## Constructing the QNode

Now that we have initialized our device, we can begin to construct a
quantum node (or QNode).

Definition

QNodes are an abstract encapsulation of a quantum function, described by a
quantum circuit. QNodes are bound to a particular quantum device, which is
used to evaluate expectation and variance values of this circuit.

Tip

QNodes can be constructed via the`QNode`class, or by using the provided`qnode()` decorator.

First, we need to define the quantum function that will be evaluated in the QNode:

```
defcircuit(params):    qp.RX(params[0], wires=0)
    qp.RY(params[1], wires=0)
return qp.expval(qp.PauliZ(0))

```

This is a simple circuit, matching the one described above.
Notice that the function `circuit()` is constructed as if it were any
other Python function; it accepts a positional argument `params`, which may
be a list, tuple, or array, and uses the individual elements for gate parameters.

However, quantum functions are a restricted subset of Python functions.
For a Python function to also be a valid quantum function, there are some
important restrictions:

-
Quantum functions must contain quantum operations, one operation per line,
in the order in which they are to be applied.

In addition, we must always specify the subsystem the operation applies to,
by passing the `wires` argument; this may be a list or an integer, depending
on how many wires the operation acts on.

For a full list of quantum operations, see the documentation.

-
Quantum functions must return either a single or a tuple of measured observables.

As a result, the quantum function always returns a classical quantity, allowing
the QNode to interface with other classical functions (and also other QNodes).

For a full list of observables, see the documentation.
The documentation also provides details on supported measurement return types.

Note

Certain devices may only support a subset of the available PennyLane
operations/observables, or may even provide additional operations/observables.
Please consult the documentation for the plugin/device for more details.

Once we have written the quantum function, we convert it into a `QNode` running
on device `dev1` by applying the `qnode()` decorator.
directly above the function definition:

```
@qp.qnode(dev1)defcircuit(params):    qp.RX(params[0], wires=0)
    qp.RY(params[1], wires=0)
return qp.expval(qp.PauliZ(0))

```

Thus, our `circuit()` quantum function is now a `QNode`, which will run on
device `dev1` every time it is evaluated.

To evaluate, we simply call the function with some appropriate numerical inputs:

```
params = np.array([0.54, 0.12])
print(circuit(params))

```

```
0.85154057

```

## Calculating quantum gradients

The gradient of the function `circuit`, encapsulated within the `QNode`,
can be evaluated by utilizing the same quantum
device (`dev1`) that we used to evaluate the function itself.

PennyLane incorporates both analytic differentiation, as well as numerical
methods (such as the method of finite differences). Both of these are done
automatically.

We can differentiate by using the jax.grad function.
This returns another function, representing the gradient (i.e., the vector of
partial derivatives) of `circuit`. The gradient can be evaluated in the same
way as the original function:

```
dcircuit = jax.grad(circuit, argnums=0)

```

The function jax.grad itself returns a function, representing
the derivative of the QNode with respect to the argument specified in `argnums`.
In this case, the function `circuit` takes one argument (`params`), so we
specify `argnums=0`. Because the argument has two elements, the returned gradient
is two-dimensional. We can then evaluate this gradient function at any point in the parameter space.

```
print(dcircuit(params))

```

```
[-0.5104387  -0.10267819]

```

A note on arguments

Quantum circuit functions, being a restricted subset of Python functions,
can also make use of multiple positional arguments and keyword arguments.
For example, we could have defined the above quantum circuit function using
two positional arguments, instead of one array argument:

```
@qp.qnode(dev1)defcircuit2(phi1, phi2):    qp.RX(phi1, wires=0)
    qp.RY(phi2, wires=0)
return qp.expval(qp.PauliZ(0))

```

When we calculate the gradient for such a function, the usage of `argnums`
will be slightly different. In this case, `argnums=0` will return the gradient
with respect to only the first parameter (`phi1`), and `argnums=1` will give
the gradient for `phi2`. To get the gradient with respect to both parameters,
we can use `argnums=[0,1]`:

```
phi1 = np.array(0.54)
phi2 = np.array(0.12)
dcircuit = jax.grad(circuit2, argnums=[0, 1])
print(dcircuit(phi1, phi2))

```

```
(Array(-0.5104387, dtype=float32), Array(-0.10267819, dtype=float32))

```

Keyword arguments may also be used in your custom quantum function. PennyLane
does not differentiate QNodes with respect to keyword arguments,
so they are useful for passing external data to your QNode.

## Optimization

Definition

PennyLane offers a powerful and flexible interface for gradient-based optimization.
When using the JAX interface, we can leverage any JAX-compatible optimizer,
such as those provided by Optax or
JAXopt, to optimize our hybrid quantum-classical
cost functions.

Tip

SeeGradients and trainingfor details and documentation of available optimizers

Next, let’s make use of a JAX-compatible optimizer to optimize the two circuit
parameters \(\phi_1\) and \(\phi_2\) such that the qubit, originally in state
\(\left|0\right\rangle,\) is rotated to be in state \(\left|1\right\rangle.\) This is equivalent to measuring a
Pauli-Z expectation value of \(-1,\) since the state \(\left|1\right\rangle\) is an eigenvector
of the Pauli-Z matrix with eigenvalue \(\lambda=-1.\)

In other words, the optimization procedure will find the weights
\(\phi_1\) and \(\phi_2\) that result in the following rotation on the Bloch sphere:

To do so, we need to define a cost function. By minimizing the cost function, the
optimizer will determine the values of the circuit parameters that produce the desired outcome.

In this case, our desired outcome is a Pauli-Z expectation value of \(-1.\) Since we
know that the Pauli-Z expectation is bound between \([-1, 1],\) we can define our
cost directly as the output of the QNode:

```
defcost(x):return circuit(x)

```

To begin our optimization, let’s choose small initial values of \(\phi_1\) and \(\phi_2:\)

```
init_params = np.array([0.011, 0.012])
print(cost(init_params))

```

```
0.9998675

```

We can see that, for these initial parameter values, the cost function is close to \(1.\)

Finally, we use an optimizer to update the circuit parameters for 100 steps. We can use the
gradient descent optimizer provided by JAXopt:

```
import jaxopt
# initialise the optimizeropt = jaxopt.GradientDescent(cost, stepsize=0.4, acceleration = False)
# set the number of stepssteps = 100# set the initial parameter valuesparams = init_params
opt_state = opt.init_state(params)
for i inrange(steps):
# update the circuit parameters    params, opt_state = opt.update(params, opt_state)
if (i + 1) % 5 == 0:
print("Cost after step {:5d}: {: .7f}".format(i + 1, cost(params)))
print("Optimized rotation angles: {}".format(params))

```

```
Cost after step     5:  0.9961779
Cost after step    10:  0.8974943
Cost after step    15:  0.1440490
Cost after step    20: -0.1536721
Cost after step    25: -0.9152496
Cost after step    30: -0.9994046
Cost after step    35: -0.9999964
Cost after step    40: -1.0000000
Cost after step    45: -1.0000000
Cost after step    50: -1.0000000
Cost after step    55: -1.0000000
Cost after step    60: -1.0000000
Cost after step    65: -1.0000000
Cost after step    70: -1.0000000
Cost after step    75: -1.0000000
Cost after step    80: -1.0000000
Cost after step    85: -1.0000000
Cost after step    90: -1.0000000
Cost after step    95: -1.0000000
Cost after step   100: -1.0000000
Optimized rotation angles: [7.1526556e-18 3.1415925e+00]

```

We can see that the optimization converges after approximately 40 steps.

Substituting this into the theoretical result \(\langle \psi \mid \sigma_z \mid \psi \rangle = \cos\phi_1\cos\phi_2,\)
we can verify that this is indeed one possible value of the circuit parameters that
produces \(\langle \psi \mid \sigma_z \mid \psi \rangle=-1,\) resulting in the qubit being rotated
to the state \(\left|1\right\rangle.\)

```
## Continue on to the next tutorial, :doc:`gaussian transformation <demos/tutorial_gaussian_transformation>`, to see a similar example using# continuous-variable (CV) quantum nodes.#
```

## About the author

Josh Izaac

Josh is a theoretical physicist, software tinkerer, and occasional baker. At Xanadu, he contributes to the development and growth of Xanadu’s open-source quantum software products.

Total running time of the script: (0 minutes 0.747 seconds)

Share demo

-

-

-

Ask a question on the forum

### Related Demos

Plugins and hybrid computation

Gaussian transformation

Training a quantum circuit with PyTorch

PyTorch and noisy devices

How to optimize a QML model using JAX and JAXopt

Noisy circuits

How to optimize a QML model using Catalyst and quantum just-in-time (QJIT) compilation

Getting started with the Amazon Braket Hybrid Jobs

Optimizing noisy circuits with Cirq

How to optimize a QML model using JAX and Optax

-

-

-

-

-

-

-

-

###

-

####

-

####

-

####

-

####

-

####

-

####

###

-

####

-

####

-

####

-

####

-

####

-

####

###

-

####

-

####

-

####

-

####

-

####

-

####

-

####

-

####

-

-

-

-

-

-

-
