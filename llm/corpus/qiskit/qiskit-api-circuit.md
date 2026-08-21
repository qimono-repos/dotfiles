---
source: https://docs.quantum.ibm.com/api/qiskit/circuit
fetched: 2026-08-21
---

circuit (latest version) | IBM Quantum Documentation

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

# Quantum circuit model

`qiskit.circuit`

The fundamental element of quantum computing is the quantum circuit. This is a computational routine that can be run, one shot at a time, on a quantum processing unit (QPU). A circuit will act on a predefined amount of quantum data (in Qiskit, we only directly support qubits) with unitary operations (gates), measurements and resets. In addition, a quantum circuit can contain operations on classical data, including real-time computations and control-flow constructs, which are executed by the controllers of the QPU.

Note

You may wish to skip the introductory material and jump directly to:

- the API overview of the whole circuit module

- the detailed discussion about how circuits are represented

- the core `QuantumCircuit` class for how to build and query circuits

- information on construction custom instructions

- ways to work with circuit-level objects

- discussion of Qiskit conventions for circuits, matrices and state labelling

Circuits are at a low level of abstraction when building up quantum programs. They are the construct that is used to build up to higher levels of abstraction, such as the primitives of quantum computation, which accumulate data from many shots of quantum-circuit execution, along with advanced error-mitigation techniques and measurement optimizations, into well-typed classical data and error statistics.

In Qiskit, circuits can be defined in one of two regimes:

- an abstract circuit, which is defined in terms of virtual qubits and arbitrary high-level operations, like encapsulated algorithms and user-defined gates.

- a physical circuit, which is defined in terms of the hardware qubits of one particular backend, and contains only operations that this backend natively supports. You might also see this concept referred to as an ISA circuit.

You convert from an abstract circuit to a physical circuit by using Qiskit’s transpilation package, of which the top-level access point is `transpile()`. If you define a circuit, where you intend the qubit indices to refer to physical qubits, you can use `QuantumCircuit.ensure_physical()` to rewrite the circuit’s metadata to ensure that Qiskit recognizes the circuit as a physical circuit, though unlike transpilation, this does not enforce that the basis-gates and hardware-coupling constraints will be respected.

In Qiskit, a quantum circuit is represented by the `QuantumCircuit` class. Below is an example of a quantum circuit that makes a three-qubit Greenberger–Horne–Zeilinger (GHZ) state defined as:
∣ψ⟩=(∣000⟩+∣111⟩)/2|\psi\rangle = \left( |000\rangle + |111\rangle \right) / \sqrt{2}∣ψ⟩=(∣000⟩+∣111⟩)/2​

```
from qiskit import QuantumCircuit# Create a circuit with a register of three qubitscirc = QuantumCircuit(3)# H gate on qubit 0, putting this qubit in a superposition of |0> + |1>.circ.h(0)# A CX (CNOT) gate on control qubit 0 and target qubit 1 generating a Bell state.circ.cx(0, 1)# CX (CNOT) gate on control qubit 0 and target qubit 2 resulting in a GHZ state.circ.cx(0, 2)# Draw the circuitcirc.draw('mpl')
```

## Circuit concepts and definitions

There is a lot of specialized terminology around quantum circuits. Much of this is common in quantum-computing literature, while some is more specific to quantum software packages, and a small amount specific to Qiskit. This is an alphabetical listing of some of the important concepts as a quick reference, but does not go into detail of the foundational concepts. Consider using the IBM Quantum Learning platform if you want to start from the beginning.

abstract circuit

A circuit defined in terms of abstract mathematical operations and virtual qubits. This is typically how you think about quantum algorithms; an abstract circuit can be made up of completely arbitrary unitary operations, measurements, and potentially real-time classical computation, with no restrictions about which qubits can interact with each other.

You turn an abstract circuit into a physical circuit by using Qiskit’s transpilation package.

ancilla qubit

An extra qubit that is used to help implement operations on other qubits, but whose final state is not important for the program.

circuit

A computational routine the defines a single execution to be taken on a QPU. This can either be an abstract circuit or a physical circuit.

clbit

A Qiskit-specific abbreviation meaning a single classical bit of data.

gate

A unitary operation on one or more qubits.

hardware qubit

The representation of a single qubit on a particular QPU. A hardware qubit has some physical quantum-mechanical system backing it, such as superconducting circuits; unlike a virtual qubit, it has particular coupling constraints and only certain gates can be applied to certain groups of hardware qubits.

Qiskit does not distinguish logical qubits from any individual physical qubits when talking about hardware qubits. A QPU may implement its hardware qubits as logical qubits, where each hardware qubit comprises many physical qubits that are controlled and error-corrected opaquely to Qiskit by the control electronics. More likely, for near-term applications, a QPU will be directly exposing its physical qubits as the hardware qubits for Qiskit to reason about.

Both physical and logical qubits will have coupling constraints between them, only permit certain quantum operations on them, and have scheduling concerns between them. Qiskit abstracts these concerns together in the concept of hardware qubits. In the early days of quantum error correction, particular backends may let you access their qubit resources either as high-level logical qubits or as low-level physical qubits through Qiskit.

instruction set architecture (ISA)

The abstract model of which operations are available on which sets of hardware qubits on one particular QPU. For example, one QPU may allow X\sqrt XX​ and RZR_ZRZ​ operations on all single hardware qubits, and CXCXCX operations on certain pairs of hardware qubits.

logical qubit

A collection of several physical qubits that are controlled together by a QPU (from the user’s perspective) to apply real-time quantum error correction. A logical qubit is a type of hardware qubit for Qiskit.

measurement

The act of extracting one classical bit of a data from a single qubit state. This is an irreversible operation, and usually destroys entanglement and phase coherence between the target qubit and the rest of the system.

physical circuit

A circuit defined in terms of hardware qubits and only the quantum operations available in a particular QPU’sISA. Physical circuits are tied to one particular QPU architecture, and will not run on other incompatible architectures. You may also hear this referred to as an ISA circuit.

You typically get a physical circuit by using Qiskit’s transpilation routines on an abstract circuit that you constructed.

physical qubit

A controllable two-level quantum system. This is literally one “physics” qubit, such as a transmon or the electronic state of a trapped ion. A QPU may expose this directly as its hardware qubit, or combine several physical qubits into a logical qubit.

quantum processing unit (QPU)

Analogous to a CPU in classical computing or a GPU in graphics processing, a QPU is the hardware that runs quantum operations on quantum data. You can always expect a QPU that uses the circuit model of computation to be able to perform some set of gates, and measurement operations. Depending on the particular technology, they also may be able to run some real-time classical computations as well, such as classical control flow and bitwise calculations on classical data.

qubit

The basic unit of quantum information.

real-time classical computation

Any classical computation that can happen within the execution of a single shot of a circuit, where the results of the classical computation can affect later execution of the circuit. The amount of real-time classical computation available with particular QPUs will vary significantly dependent on many factors, such as the controlling electronics and the qubit technology in use. You should consult your hardware vendor’s documentation for more information on this.

unitary operation

A reversible operation on a quantum state. All quantum gates are unitary operations (by definition).

virtual qubit

An abstract, mathematical qubit used to build an abstract circuit. Virtual qubits are how one typically thinks about quantum algorithms at a high level; we assume that all quantum gates are valid on all virtual qubits, and all virtual qubits are always connected to every other virtual qubit.

When mapping to hardware, virtual qubits must be assigned to hardware qubits. This mapping need not be one-to-one. Typically, one virtual qubit will need to be swapped from one hardware qubit to another over the course of a circuit execution in order to satisfy coupling constraints of the underlying QPU. It is not strictly necessary for all virtual qubits used in a circuit to be mapped to a physical qubit at any given point in a physical circuit; it could be that a virtual qubit is measured (collapsing its state) and then never used again, so a new virtual qubit could take its place. Evaluating these conditions to map a virtual circuit to a physical circuit is the job of Qiskit’s transpilation package.

## API overview of qiskit.circuit

All objects here are described in more detail, and in their greater context in the following sections. This section provides an overview of the API elements documented here.

The principal class is `QuantumCircuit`, which has its own documentation page, including an in-depth section on building circuits. Quantum data and the simplest classical data are represented by “bits” and “registers”:

-
`Bit`, an atom of data

- `Qubit`

- `Clbit`

- `AncillaQubit`

-
`Register`, a collection of bits

- `QuantumRegister`

- `ClassicalRegister`

- `AncillaRegister`

Within a circuit, each complete `CircuitInstruction` is made up of an `Operation` (which might be an `Instruction`, a `Gate`, or some other subclass) and the qubit and clbit operands. The core base classes here are:

-
`CircuitInstruction`, an operation and its operands

-
`InstructionSet`, a temporary handle to a slice of circuit data

-
`Operation`, any abstract mathematical object or hardware instruction

-
`AnnotatedOperation`, a subclass with applied abstract modifiers

- `InverseModifier`

- `ControlModifier`

- `PowerModifier`

The most common concrete subclass of the minimal, abstract `Operation` interface is the `Instruction`. While `Operation` can include abstract mathematical objects, an `Instruction` is something that could conceivably run directly on hardware. This is in turn subclassed by `Gate` and `ControlledGate` that further add unitarity and controlled semantics on top:

- `Instruction`, representing a hardware-based instruction

- `Gate`, representing a hardware instruction that is unitary

- `ControlledGate`, representing a gate with control structure.

Qiskit includes a large library of standard gates and circuits, which is documented in `qiskit.circuit.library`. Many of these are declared as Python-object singletons. The machinery for this is described in detail in `qiskit.circuit.singleton`, of which the main classes are each a singleton form of the standard instruction–gate hierarchy:

- `SingletonInstruction`

- `SingletonGate`

- `SingletonControlledGate`

Some instructions are particularly special in that they affect the control flow or data flow of the circuit. The top-level ones are:

-
`Barrier`, to mark parts of the circuit that should be optimized independently

-
`Delay`, to insert a real-time wait period

-
`Measure`, to measure a `Qubit` into a `Clbit`

-
`Reset`, to irreversibly reset a qubit to the ∣0⟩\lvert0\rangle∣0⟩ state

-
`Store`, to write a real-time classical expression to a storage location

-
`ControlFlowOp`, which has specific subclasses:

- `BreakLoopOp`, to break out of the nearest containing loop

- `ContinueLoopOp`, to move immediately to the next iteration of the containing loop

- `BoxOp`, a simple grouping of instructions

- `ForLoopOp`, to loop over a fixed range of values

- `IfElseOp`, to conditionally enter one of two subcircuits

- `SwitchCaseOp`, to conditionally enter one of many subcircuits

- `WhileLoopOp`, to repeat a subcircuit until a condition is falsified.

Certain instructions can be “annotated” with metadata, which is typically intended to be consumed by a compiler pass either locally, or in later backend processing. Currently this is limited to `BoxOp`. These annotations are represented by custom subclasses of `Annotation`, and there is further discussion of the support infrastructure in `qiskit.circuit.annotation`.

Circuits can include classical expressions that are evaluated in real time, while the QPU is executing a single shot of the circuit. These are primarily documented in the module documentation of `qiskit.circuit.classical`. You might be particularly interested in the base classes (which are not exposed from the `qiskit.circuit` root):

- `Var`, a typed classical storage location in a circuit

- `Expr`, a real-time-evaluated expression

- `Type`, the classical type of an expression.

In addition to this real-time expression evaluation, which is limited by classical hardware representations of data, Qiskit has the concept of “compile-time” parametrization, which is done in abstract symbolic algebra. These are typically used to represent gate angles in high-level algorithms that might want to perform numerical derivatives, but they are an older part of Qiskit than the real-time evaluation, so are still used in some places to do general parametrization. The main related classes are:

- `Parameter`, the atom of compile-time expressions

- `ParameterExpression`, a symbolic calculation on parameters

- `ParameterVector`, a convenience collection of many `Parameter`s

- `ParameterVectorElement`, a subclass of `Parameter` used by `ParameterVector`

The `qiskit.circuit` module also exposes some calculation classes that work with circuits to assist compilation workflows. These include:

- `EquivalenceLibrary`, a database of decomposition relations between gates and circuits

- `SessionEquivalenceLibrary`, a mutable instance of `EquivalenceLibrary` which is used by default by the compiler’s `BasisTranslator`.

There are also utilities for generating random circuits:

- `random.random_circuit()`

- `random.random_circuit_from_graph()`

- `random.random_clifford_circuit()`

Finally, the circuit module has its own exception class, to indicate when things went wrong in circuit-specific manners:

- `CircuitError`

## Representation of circuits in Qiskit

The main user-facing class for representing circuits is `QuantumCircuit`. This can be either an abstract circuit or a physical circuit. There is much more information about the `QuantumCircuit` class itself and the multitude of available methods on it in its class documentation.

Internally, a `QuantumCircuit` contains the qubits, classical bits, compile-time parameters, real-time variables, and other tracking information about the data it acts on and how it is parametrized. It then contains a sequence of `CircuitInstruction`s, which contain the particular operation (gate, measurement, etc) and its operands (the qubits and classical bits).

### Bits and registers

Qubits and classical bits are represented by a shared base `Bit` type, which is just intended to be a “type tag”; the classes have no behavior other than being immutable objects:

#### Bit

class`qiskit.circuit.Bit`
GitHub
Bases: `object`

Implement a generic bit.

Note

This class cannot be instantiated directly. Its only purpose is to allow generic type checking for `Clbit` and `Qubit`.

#### Qubit

class`qiskit.circuit.Qubit(register=None, index=None)`
GitHub
Bases: `Bit`

A qubit, which can be compared between different circuits.

#### Clbit

class`qiskit.circuit.Clbit(register=None, index=None)`
GitHub
Bases: `Bit`

A clbit, which can be compared between different circuits.

Qubits and clbits are instantiated by users with no arguments, such as by `Qubit()`. Bits compare equal if they are the same Python object, or if they were both created by a register of the same name and size, and they refer to the same index within that register. There is also a special type tag for “ancilla” qubits, but this is little used in the current state of Qiskit:

#### AncillaQubit

class`qiskit.circuit.AncillaQubit`
GitHub
Bases: `Qubit`

A qubit used as an ancilla.

A collection bits of the same type can be encapsulated in a register of the matching type. The base functionality is in a base class that is not directly instantiated:

#### Register

class`qiskit.circuit.Register`
GitHub
Bases: `object`

Implement a generic register.

Note

This class cannot be instantiated directly. Its only purpose is to allow generic type checking for `ClassicalRegister` and `QuantumRegister`.

Each of the defined bit subtypes has an associated register, which have the same constructor signatures, methods and properties as the base class:

#### QuantumRegister

class`qiskit.circuit.QuantumRegister(size=None, name=None, bits=None)`
GitHub
Bases: `Register`

Implement a register.

#### ClassicalRegister

class`qiskit.circuit.ClassicalRegister(size=None, name=None, bits=None)`
GitHub
Bases: `Register`

Implement a register.

#### AncillaRegister

class`qiskit.circuit.AncillaRegister(size=None, name=None, bits=None)`
GitHub
Bases: `QuantumRegister`

Implement an ancilla register.

A common way to instantiate several bits at once is to create a register, such as by `QuantumRegister("my_qreg", 5)`. This has the advantage that you can give that collection of bits a name, which will appear during circuit visualizations (`QuantumCircuit.draw()`) and exports to interchange languages (see `qasm2` and `qasm3`). You can also pass a name and a list of pre-constructed bits, but this creates an “aliasing register”, which are very poorly supported on hardware.

Circuits track registers, but registers themselves impart almost no behavioral differences on circuits. The only exception is that `ClassicalRegister`s can be implicitly cast to unsigned integers for use in conditional comparisons of control flow operations.

Classical registers and bits were the original way of representing classical data in Qiskit, and remain the most supported currently. Longer term, the data model is moving towards a more complete and strongly typed representation of a range of classical data (see Real-time classical computation), but you will still very commonly use classical bits in current Qiskit.

### Instruction contexts

The scalar type of the `QuantumCircuit.data` sequence is the “instruction context” object, `CircuitInstruction`. This is essentially just a data class that contains a representation of what is to be done (its `operation`), and the data it acts on (the `qubits` and `clbits`).

`CircuitInstruction`(operation[, qubits, clbits])A single instruction in a `QuantumCircuit`, comprised of the `operation` and various operands.

Programmatically, this class is actually implemented in Rust and is a constructed handle to internal data within Rust space. Mutations to instances of this class will not be reflected in the circuit. In general, you cannot mutate instruction contexts that are already in the circuit directly; the `QuantumCircuit` interface is designed for storing and building circuits, while the transpiler and its passes, and its intermediate `DAGCircuit` representation, are where you should look for an interface to mutate circuits.

The `QuantumCircuit` methods that add instructions to circuits (such as `append()`, and all the helper standard-gate methods) return an `InstructionSet`, which is a handle to several `CircuitInstruction`s simultaneously.

`InstructionSet`(*[, resource_requester])Instruction collection, and their contexts.

This `InstructionSet` is now little used in Qiskit. It provides a very minimal set of methods to perform post-append mutations on instructions (which will be propagated to the circuit), but these are now discouraged and you should use the alternatives noted in those methods.

### Operations, instructions and gates

Within a `CircuitInstruction`, the minimal interface that any operation must fulfill is `Operation`. This is a very high level view, and only usable for abstract circuits. The main purpose of treating operations as `Operation` is to allow arbitrary mathematical objects (such as `quantum_info.Operator`) to be added to abstract circuits directly.

`Operation`()Quantum operation interface.

Most operations, including all operations on physical circuits, are instances of the more concretely defined `Instruction`. This represents any instruction that some QPU might be able to carry out natively, such as `Measure`. `Instruction` need not be unitary (much as `Measure` isn’t); an instruction is specifically unitary if it is a `Gate`.

`Instruction`(name, num_qubits, num_clbits, params)Generic quantum instruction.

`Instruction`s can be near arbitrary, provided they only act on `Qubit`s and `Clbit`s, and are parametrized by their `params`; they should not attempt to “close over” outer circuit registers, or use hidden parameters inside themselves. `Instruction`s can be related to other circuits to provide a decompositions by using their `Instruction.definition` attribute, which provides a local, one-off decomposition. This can be in whatever basis set of operations is most convenient to you, as long as the definitions of all contained gates have some topological order; that is, you cannot use a gate in a definition if its own definition depends on the parent. If the `Instruction` should be considered entirely opaque to optimizers, its `definition` can be `None`. See Creating custom instructions for more detail.

The `params` of an instruction can technically be arbitrary, but in general you should attempt to stick to parametrizations in terms of real numbers, wherever possible. Qiskit itself breaks this rule in many places, and you will find all sorts of unusual types in `Instruction.params` fields, but these are an annoying source of bugs because they often imply the need for type-aware special casing. If your instruction is parametrized in terms of angles, you will be able to reliably use compile-time parametrization in it, and it will integrate well with `QuantumCircuit.assign_parameters()`.

While `Instruction` is not necessarily unitary, its subclass `Gate` implies unitarity, and adds `to_matrix()` and `control()` methods to all the methods inherited from `Instruction`.

`Gate`(name, num_qubits, params[, label])Unitary gate.

`Gate` inherits all the methods for `Instruction` and all the same considerations about its `params` and `definition` field, except of course that `Gate`s cannot act on any classical resources.

`Gate` instances can (and should) have a base `definition`, but you can also specify several different decompositions in different bases by using an `EquivalenceLibrary`.

Subclassing `Gate`, Qiskit has a special `ControlledGate` class as well. This class is the base of many standard-library gates that are controlled (such as `CXGate`), which is where you are most likely to encounter it:

`ControlledGate`(name, num_qubits, params[, ...])Controlled unitary gate.

Each of `Instruction`, `Gate` and `ControlledGate` has a corresponding singleton type, built using the machinery described in `qiskit.circuit.singleton`. The module-level documentation contains full details, along with descriptions of `SingletonInstruction`, `SingletonGate` and `SingletonControlledGate`. From a user’s perspective, little changes based on whether the base class is a singleton or not; the intention always remains that you should call `to_mutable()` first if you need to get a safe-to-mutate owned copy of an instruction (you cannot assume that an arbitrary instruction is mutable), and while direct `type` inspection is discouraged, if you do need it, the reliable way to find the “base” type of a potentially singleton instruction is to use `base_class`.

`ControlledGate` uses the same mechanisms as subclassing gates to define a fixed, lazy synthesis for itself. This is naturally not hardware-aware, and harder to hook into the synthesis routines of the compiler, but works better as a concrete `Instruction` that could potentially be run natively on hardware. For cases where synthesis and abstract optimization is more important, Qiskit offers a composable class called `AnnotatedOperation`, which tracks “gate modifiers” (of which `ControlModifier` is one) to apply to the inner `base_op`.

`AnnotatedOperation`(base_op, modifiers)Annotated operation.

The available modifiers for `AnnotatedOperation` are:

#### InverseModifier

class`qiskit.circuit.InverseModifier`
GitHub
Bases: `Modifier`

Inverse modifier: specifies that the operation is inverted.

#### ControlModifier

class`qiskit.circuit.ControlModifier(num_ctrl_qubits=0, ctrl_state=None)`
GitHub
Bases: `Modifier`

Control modifier: specifies that the operation is controlled by `num_ctrl_qubits` and has control state `ctrl_state`.

Parameters

- num_ctrl_qubits (int)

- ctrl_state (int|str| None)

#### PowerModifier

class`qiskit.circuit.PowerModifier(power)`
GitHub
Bases: `Modifier`

Power modifier: specifies that the operation is raised to the power `power`.

Parameters

power (float)

For information on how to create custom gates and instructions, including how to build one-off objects, and re-usable parametric gates via subclassing, see Creating custom instructions below. The Qiskit circuit library in `qiskit.circuit.library` contains many predefined gates and circuits for you to use.

### Built-in special instructions

Qiskit contains a few `Instruction` classes that are in some ways “special”. These typically have special handling in circuit code, in the transpiler, or the models of hardware. These are all generally instructions you might already be familiar with.

Measurements in Qiskit are of a single `Qubit` into a single `Clbit`. These are the two that the instruction is applied to. Measurements are in the computational basis.

#### Measure

class`qiskit.circuit.Measure(label=None)`
GitHub
Bases: `SingletonInstruction`

Quantum measurement in the computational basis.

Parameters

label – optional string label for this instruction.

Related to measurements, there is a `Reset` operation, which produces no classical data but instructs hardware to return the qubit to the ∣0⟩\lvert0\rangle∣0⟩ state. This is assumed to happen incoherently and to collapse any entanglement.

#### Reset

class`qiskit.circuit.Reset(label=None)`
GitHub
Bases: `SingletonInstruction`

Incoherently reset a qubit to the ∣0⟩\lvert0\rangle∣0⟩ state.

Parameters

label – optional string label of this instruction.

Hardware can be instructed to apply a real-time idle period on a given qubit. A scheduled circuit (see `qiskit.transpiler`) will include all the idle times on qubits explicitly in terms of this `Delay`. `BoxOp` can also have an explicit duration attached, in its `BoxOp.duration` field.

#### Delay

class`qiskit.circuit.Delay(duration, unit=None)`
GitHub
Bases: `Instruction`

Do nothing and just delay/wait/idle for a specified duration.

Parameters

- duration – the length of time of the duration. If this is an `Expr`, it must be a constant expression of type `Duration` and the `unit` parameter should be omitted (or MUST be “expr” if it is specified).

- unit – the unit of the duration, if `duration` is a numeric value. Must be `"dt"`, an SI-prefixed seconds unit, or “expr”.

Raises

CircuitError – A `duration` expression was specified with a resolved type that is not timing-based, or the `unit` was improperly specified.

Delay durations can be specified either with concrete, constant times, or with delayed-resolution “duration expressions” built out of `expr.Stretch` objects. See Delayed-resolution scheduling for more on this.

The `Barrier` instruction can span an arbitrary number of qubits and clbits, and is a no-op in hardware. During transpilation and optimization, however, it blocks any optimizations from “crossing” the barrier; that is, in:

```
from qiskit.circuit import QuantumCircuitqc = QuantumCircuit(1)qc.x(0)qc.barrier()qc.x(0)
```

it is forbidden for the optimizer to cancel out the two XXX instructions.

#### Barrier

class`qiskit.circuit.Barrier(num_qubits, label=None)`
GitHub
Bases: `Instruction`

A directive for circuit compilation to separate pieces of a circuit so that any optimizations or re-writes are constrained to only act between barriers.

This will also appear in visualizations as a visual marker.

Parameters

- num_qubits (int) – the number of qubits for the barrier.

- label (str| None) – the optional label of this barrier.

The `Store` instruction is particularly special, in that it allows writing the result of a real-time classical computation expression (an `expr.Expr`) in a local classical variable (a `expr.Var`). It takes neither`Qubit` nor `Clbit` operands, but has an explicit `lvalue` and `rvalue`.

For example, to determine the parity of a bitstring `cr` and store it in another register `creg`, the `Store` instruction can be used in the following way:

```
parity = expr.lift(cr[0])for i in range(1,n):    parity = expr.bit_xor(cr[i], parity)qc.store(creg[0], parity)
```

#### Store

class`qiskit.circuit.Store(lvalue, rvalue)`
GitHub
Bases: `Instruction`

A manual storage of some classical value to a classical memory location.

This is a low-level primitive of the classical-expression handling (similar to how `Measure` is a primitive for quantum measurement), and is not safe for subclassing.

Parameters

- lvalue (expr.Expr) – the memory location being stored into.

- rvalue (expr.Expr) – the expression result being stored.

lvalue

Get the l-value `Expr` node that is being stored to.

rvalue

Get the r-value `Expr` node that is being written into the l-value.

### Real-time classical computation

See also

`qiskit.circuit.classical`

Module-level documentation for how the variable-, expression- and type-systems work, the objects used to represent them, and the classical operations available.

Working with real-time typed classical data

The `QuantumCircuit` methods for working with these variables in the context of a single circuit.

Qiskit has rudimentary low-level support for representing real-time classical computations, which happen during the QPU execution and affect the results. We are still relatively early into hardware support for these concepts as well, so beware that you will need to work closely with your hardware provider’s documentation to get the best use out of any real-time classical computation.

These real-time calculations are represented by the expression and type system in `qiskit.circuit.classical`. At a high level, all real-time expressions are represented by an `Expr` node, which is part of an expression “tree” representation, which has a well-defined `Type` associated with it at every level. See the module-level documentation for much more detail on the internal representations of these classes.

The result of a real-time `Expr` can be used directly in certain places. Currently this is limited to conditions of `IfElseOp` and `WhileLoopOp`, and the target of `SwitchCaseOp`. The result can also be stored in a typed classical storage location, using the `Store` instruction (or its `QuantumCircuit.store()` constructor), backed by a `expr.Var` node.

A circuit can contain manual classical storage locations, represented internally by the `Var` node of the `Expr` tree. These have an attached classical type (like any other expression). These can either be declared and initialized within each execution of the circuit (`add_var()`), or be inputs to the circuit (`add_input()`).

### Compile-time parametrization

Various parametric `Instruction` instances in Qiskit can be parametrized in ways that are designed to be resolved at compile time. These are characterized by the use of the `Parameter` and `ParameterExpression` classes.

`Parameter`(name[, uuid])A compile-time symbolic parameter.

`ParameterExpression`(name_map, expr)A parameter expression.

The main way that this differs from the `expr.Var` variables used in real-time classical computation is that `ParameterExpression` is a symbolic representation of a mathematical expression. The semantics of the expression are those of regular mathematics over the continuous real numbers (and, in limited cases, over the complex numbers). In contrast, `Var` is a handle to a variable stored on a classical computer, such as a floating-point value or an fixed-width integer, which are always discrete.

In other words, you can expect `ParameterExpression` to do symbolic simplifications that are valid in mathematics, such as simplifying (x+y−x)/y→1(x + y - x) / y \to 1(x+y−x)/y→1. Such a simplification is not valid in floating-point arithmetic, and `expr.Expr` will not do this.

The “compile-time” part of these parameters means that you typically will want to “assign” values to the parameters before sending the circuit for execution. These parameters can typically be used anywhere that expects a mathematical angle (like a rotation gate’s parameters), with the caveat that hardware will usually require them to be assigned to a proper classically typed value before execution. You can do this assignment using `QuantumCircuit.assign_parameters()`.

You may want to use many parameters that are related to each other. To make this easier (and to avoid you needing to come up with many names), you can use the convenience constructor `ParameterVector`. The elements of the vector are all valid `Parameter` instances, of a special subclass `ParameterVectorElement`.

`ParameterVector`(name[, length, uuid])A container of many related `Parameter` objects.

`ParameterVectorElement`(vector, index[, uuid])An element of a `ParameterVector`.

### Control flow in circuits

Within `QuantumCircuit`, classical control flow is represented by specific `Instruction`s, which are subclasses of `ControlFlowOp`.

`ControlFlowOp`(name, num_qubits, num_clbits, ...)Abstract class to encapsulate all control flow operations.

For convenience, there is a `frozenset` instance containing the `Instruction.name` attributes of each of the control-flow operations.

#### qiskit.circuit.CONTROL_FLOW_OP_NAMES

Set of the instruction names of Qiskit’s known control-flow operations.

The `get_control_flow_name_mapping()` function allows to access the control-flow operation classes associated to each name.

#### get_control_flow_name_mapping

`qiskit.circuit.get_control_flow_name_mapping()`
GitHub
Return a dictionary mapping the names of control-flow operations to their corresponding classes.”

Examples

```
from qiskit.circuit import get_control_flow_name_mappingctrl_flow_name_map = get_control_flow_name_mapping()if_else_object = ctrl_flow_name_map["if_else"]print(if_else_object)
```

```
<class 'qiskit.circuit.controlflow.if_else.IfElseOp'>
```

These control-flow operations (`IfElseOp`, `WhileLoopOp`, `SwitchCaseOp`, `ForLoopOp`, and `BoxOp`) all have specific state that defines the branching conditions and strategies, but contain all the different subcircuit blocks that might be entered in their `blocks` property.

`IfElseOp`(condition, true_body[, false_body, ...])A circuit operation which executes a program (`true_body`) if a provided condition (`condition`) evaluates to true, and optionally evaluates another program (`false_body`) otherwise.

`WhileLoopOp`(condition, body[, label])A circuit operation which repeatedly executes a subcircuit (`body`) until a condition (`condition`) evaluates as False.

`SwitchCaseOp`(target, cases, *[, label])A circuit operation that executes one particular circuit block based on matching a given `target` against an ordered list of `values`.

`ForLoopOp`(indexset, loop_parameter, body[, ...])A circuit operation which repeatedly executes a subcircuit (`body`) parameterized by a parameter `loop_parameter` through the set of integer values provided in `indexset`.

`BoxOp`(body[, duration, unit, label, annotations])A scoped "box" of operations on a circuit that are treated atomically in the greater context.

The `SwitchCaseOp` also understands a special value:

#### qiskit.circuit.CASE_DEFAULT

Default value: `<default case>`

A special object that represents the “default” case of a switch statement. If you use this as a case target, it must be the last case, and will match anything that wasn’t already matched. When using the builder interface of `QuantumCircuit.switch()`, this can also be accessed as the `DEFAULT` attribute of the bound case-builder object.

In addition to the block-structure control-flow operations, there are also two special instructions that affect the flow of control when within loops. These correspond to typical uses of the `break` and `continue` statements in classical programming languages.

`BreakLoopOp`(num_qubits, num_clbits[, label])A circuit operation which, when encountered, jumps to the end of the nearest enclosing loop.

`ContinueLoopOp`(num_qubits, num_clbits[, label])A circuit operation which, when encountered, moves to the next iteration of the nearest enclosing loop.

Note

The classes representations are documented here, but please note that manually constructing these classes is a low-level operation that we do not expect users to need to do frequently.

Users should read Adding control flow to circuits for the recommended workflows for building control-flow-enabled circuits.

Since `ControlFlowOp` subclasses are also `Instruction` subclasses, this means that the way they are stored in `CircuitInstruction` instances has them “applied” to a sequence of qubits and clbits in its `qubits` and `clbits` attributes. This can lead to subtle data-coherence problems: the `Qubit` and `Clbit` objects used inside the subcircuit blocks of the control-flow ops will not necessarily be identical to the corresponding objects in the `CircuitInstruction`. Any code that consumes control-flow operations in Qiskit needs to be aware of this; within a subcircuit, you should treat `subcircuit.qubits[i]` as if it were really `outer_instruction.qubits[i]`, and so on. You can generate an easy lookup table for this by doing:

```
cf_instruction: CircuitInstruction = ...cf_operation: ControlFlowOp = cf_instruction.operationfor block in blocks:    # Mappings of "inner" qubits/clbits to the outer ones.    qubit_map = dict(zip(block.qubits, cf_instruction.qubits))    clbit_map = dict(zip(block.clbits, cf_instruction.clbits))    # ... do something with `block` ...
```

Remember that you will need to propagate this information if you recurse into subblocks of control-flow operations.

All the subcircuit blocks in a `ControlFlowOp` are required to contain the same numbers of `Qubit`s and `Clbit`s, referring to the same outer bits in the same order, such that the `zip` loop given in the code block above works. The inner-circuit `Bit` objects do not need to be literally the same objects. When using the control-flow builder interface (which, it cannot be stressed enough, is highly recommended for users), the builders will arrange that the inner bit objects are identical to the outer bit objects; the `qubit_map` in the code block above will always be a mapping `{x: x}`, but if you are consuming the blocks, you should be prepared for the case that the mapping is required.

Any `ClassicalRegister`s used in a control-flow subcircuit must also be present in all containing blocks (i.e. any containing control-flow operations, and the outermost circuit), and all blocks in the same `ControlFlowOp` need to contain the same registers. Again, the builder interface will arrange for this to be the case (or produce an eager error if they cannot).

When the low-level construction is being used the inner `QuantumCircuit` blocks must manually close over any outer-scope real-time classical computation variables that they use. This is marked by these being in the `iter_captured_vars()` iterator for that block. Libraries constructing these blocks manually will need to track these captures when building control-flow circuit blocks and add them to the block using `add_capture()` (or the `captures` constructor argument), but user code will typically use the control-flow builder interface, which handles this automatically.

Consult the control-flow construction documentation for more information on how to build circuits with control flow.

### Instruction-local annotations

See also

`qiskit.circuit.annotation`

The module-level discussion of the annotation framework, including how to defined custom annotations, and how the system interacts with the compiler and with serialization to other formats.

Certain circuit instructions can be “annotated” with instruction-local annotations. As of Qiskit 2.1.0, this is limited to `BoxOp`. All annotations are subclasses of one base interface-defining object, but typically represent entirely custom analyses and commands.

`Annotation`(*args, **kwargs)An arbitrary annotation for instructions.

### Investigating commutation relations

If two operations in a circuit commute, we can swap the order in which they are applied. This can allow for optimizations and simplifications, for example, if it allows to merge or cancel gates:

```
     ┌─────────┐     ┌─────────┐               ┌─────────┐q_0: ┤ Rz(0.5) ├──■──┤ Rz(1.2) ├──■──     q_0: ┤ Rz(1.7) ├     └─────────┘┌─┴─┐└──┬───┬──┘┌─┴─┐  =       └──┬───┬──┘q_1: ───────────┤ X ├───┤ X ├───┤ X ├     q_1: ───┤ X ├───                └───┘   └───┘   └───┘             └───┘
```

Performing these optimizations are part of the transpiler, but the tools to investigate commutations are available in the `CommutationChecker`.

`CommutationChecker`([...])Check commutations of two operations.

### Delayed-resolution scheduling

Typically, the output of Qiskit’s compiler cannot be directly executed on a QPU. First, it is likely to pass through some vendor-specific pulse-level compiler, which converts the gates and measurements into signals to the controlling electronics of the QPU. While Qiskit’s `Target` can represent some of the timing constraints that these pulses will have, it is generally not entirely complete. This is especially true when dynamic circuits (feed-forward operations) are involved; the delays induced by the classical components are often dependent on low-level post-optimization details of backend compilers, and cannot be known by Qiskit.

In these situations, a user can still exert control over the relative scheduling of pulses, such as for dynamical decoupling, by using “stretch” durations. These are constructed by `QuantumCircuit.add_stretch()`, and interact with the classical-expression system described in `qiskit.circuit.classical`, although they are not real-time mutable.

For example, we can add stretches and boxes to set up a system where two separate dynamic-decoupling sequences are applied to the same qubit, while a pair of other qubits undergoes a delay of unknown duration. The two sequences are constrained to have the same length, even though internally the concrete DD pulses have differing lengths.

```
from qiskit import QuantumCircuitfrom qiskit.circuit.classical import exprqc = QuantumCircuit(3, 3)# This sets up three duration "degrees of freedom" that will# be resolved later by a backend compiler.a = qc.add_stretch("a")b = qc.add_stretch("b")c = qc.add_stretch("c")# This set of operations involves feed-forward operations that# Qiskit cannot know the length of.with qc.box():    qc.h(1)    qc.cx(1, 2)    qc.measure([1, 2], [1, 2])    with qc.if_test(expr.equal(qc.clbits[1], qc.clbits[2])):        qc.h(1)# While that stuff is happening to qubits (1, 2), we want# qubit 0 to do two different DD sequences.  The two DD# sequences are fixed to be the same length as each other,# even though they're both internally stretchy.with qc.box(duration=a):    # Textbook NMRish XX DD.    qc.delay(b, 0)    qc.x(0)    qc.delay(expr.mul(2, b), 0)    qc.x(0)    qc.delay(b, 0)with qc.box(duration=a):    # XY4-like DD.    for _ in range(2):        qc.delay(c, 0)        qc.y(0)        qc.delay(expr.mul(2, c), 0)        qc.x(0)        qc.delay(c, 0)
```

## Creating custom instructions

If you wish to create simple one-off instructions or gates that will be added to a circuit, and the blocks are just being used for visualization or grouping purposes, the easiest way to create a custom instruction or gate is simply to build its definition as a `QuantumCircuit`, and then use its `to_instruction()` or `to_gate()` method as appropriate. The results can be given directly to `QuantumCircuit.append()` on the larger circuit. These methods will create base `Instruction` or `Gate` instances whose `definition` attribute is the circuit as supplied, meaning it will automatically be accessible to the transpiler, and to other Qiskit functions that attempt to decompose circuits.

Note that standalone instructions and gates should act only on qubits and clbits; instructions that need to use complex control-flow will need to be inlined onto the `QuantumCircuit` using `compose()`.

### Creating instruction subclasses

The base classes `Instruction`, `Gate` and `ControlledGate` are all designed to be safe to subclass, and have hook points for subclasses to implement. If your custom gate is parameterless and stateless, you may also want to derive from the corresponding singleton class in `qiskit.circuit.singleton`, such as `SingletonGate`. You should consult the documentation in `qiskit.circuit.singleton` for additional methods and hook points for the singleton machinery.

Subclasses should typically define a default constructor that calls the :class`super` constructor with the correct arguments for your instruction. It is permissible to have extra state in the class, but your subclasses will most reliably integrate with the rest of the Qiskit machinery if you depend only on your `Instruction.params`, and these parameters are purely gate angles.

Subclasses of `Instruction` (or one of its subclasses) should implement the private `Instruction._define()` method, which lazily populates the hidden `_definition` cache that backs the public `definition` method.

#### _define

`Instruction._define()`
GitHub
Populate the cached `_definition` field of this `Instruction`.

Subclasses should implement this method to provide lazy construction of their public `definition` attribute. A subclass can use its `params` at the time of the call. The method should populate `_definition` with a `QuantumCircuit` and not return a value.

In subclasses of `ControlledGate`, the `_define()` method should implement the decomposition only for the all-ones control state. The `ControlledGate.definition` machinery will modify this to handle the actual control state.

If the subclass is using the singleton machinery, beware that `_define()` will be called eagerly immediately after the class-body statement has been executed, in order to produce the definition object for the canonical singleton object. This means that your definition must only use gates that are already defined; if you are writing a library with many singleton gates, you will have to order your files and imports to ensure that this is possible.

Subclasses of `Gate` will also likely wish to override the Numpy array-protocol instance method, `__array__`. This is used by `Gate.to_matrix()`, and has the signature:

#### __array__

`object.__array__(dtype=None, copy=None)`

Return a Numpy array representing the gate. This can use the gate’s `params` field, and may assume that these are numeric values (assuming the subclass expects that) and not compile-time parameters.

For greatest efficiency, the returned array should default to a dtype of `complex`.

If your custom subclass has natural representations of its controlled or inverse forms, you may also wish to override the `inverse()` and `control()` methods.

As an example of defining a custom RxzR_{xz}Rxz​ gate; that is, a single-angle rotation about the XZXZXZ axis. This is essentially `RZXGate`, if the qubits were the other way around, so we will write our definition in terms of that. We are parametric, so cannot be a singleton, but we are unitary, so should be a `Gate`:

```
import mathimport numpy as npfrom qiskit.circuit import Gate, QuantumCircuitclass RXZGate(Gate):    def __init__(self, theta):        # Initialize with our name, number of qubits and parameters.        super().__init__("rxz", 2, [theta])    def _define(self):        # Our base definition is an RZXGate, applied "backwards".        defn = QuantumCircuit(2)        defn.rzx(1, 0)        self._definition = defn    def inverse(self, annotated = False):        # We have an efficient representation of our inverse,        # so we'll override this method.        return RXZGate(-self.params[0])    def power(self, exponent: float):        # Also we have an efficient representation of power.        return RXZGate(exponent * self.params[0])    def __array__(self, dtype=None, copy=None):        if copy is False:            raise ValueError("unable to avoid copy while creating an array as requested")        cos = math.cos(0.5 * self.params[0])        isin = 1j * math.sin(0.5 * self.params[0])        return np.array([            [cos, -isin, 0, 0],            [-isin, cos, 0, 0],            [0, 0, cos, isin],            [0, 0, isin, cos],        ], dtype=dtype)
```

In this example, we defined a base definition in terms of `RZXGate`, but to enable faster decompositions to a range of bases, we might want to add some more equivalences to `SessionEquivalenceLibrary`. Note that the `BasisTranslator` translation search will search through all possible equivalences at all possible depths, so providing an equivalence in terms of (say) `XGate` will automatically make decompositions in terms of `RXGate` available as well.

Let us add an equivalence in terms of HHH, CXCXCX and RzR_zRz​ for an arbitrary symbolic parameter:

```
from qiskit.circuit import SessionEquivalenceLibrary, Parametertheta = Parameter("theta")equiv = QuantumCircuit(2)equiv.h(0)equiv.cx(1, 0)equiv.rz(theta, 0)equiv.cx(1, 0)equiv.h(0)SessionEquivalenceLibrary.add_equivalence(RZXGate(theta), equiv)
```

After this, for the duration of the Python interpreter session, translators like `BasisTranslator` will find our new definition in their search.

## Working with circuit-level objects

### Converting abstract circuits to physical circuits

An abstract `QuantumCircuit` cannot reliably be run on hardware. You might be able to use some of the high-level simulators linked to in Simulating circuits to produce quick results for small scale circuits, but to run utility-scale circuits, you will need to use real hardware, which involves compiling to a physical circuit.

The high-level function to do this is `transpile()`; it takes in an abstract circuit and a hardware `backend` or `target`, and returns a physical circuit. To get more access and control over the stages of the passes that will be run, use `generate_preset_pass_manager()` to build a `StagedPassManager` first, which you can then modify.

The full transpilation and compilation machinery is described in detail in the `qiskit.transpiler` module documentation, and detail on all the passes built into Qiskit is available in `qiskit.transpiler.passes`.

### Simulating circuits

While not part of the `qiskit.circuit` interface, one of the most common needs is to get quick simulation results for `QuantumCircuit` objects. This section provides a quick jumping-off point to other places in the documentation to find the relevant information.

For unitary circuits, you can simulate the effects on the ∣0⋯0⟩\lvert0\dotsm0\rangle∣0⋯0⟩ state by passing the `QuantumCircuit` directly to the `Statevector` default constructor. You can similar get a unitary matrix representing the circuit as an operator by passing it to the `Operator` default constructor. If you have a physical circuit, you may want to instead pass it to `Operator.from_circuit()` method to apply transformations from the `QuantumCircuit.layout` to map it back to the “abstract” qubit space.

For a more backend-like simulation experience, there are simulator-backed implementations of all the Qiskit hardware interfaces. In particular, you might be interested in:

- `BasicProvider` and the raw backends it can return to you.

- `StatevectorSimulator` for a backend-like wrapper around `Statevector`

- The `qiskit_aer` for full, high-performance simulation capabilities.

- `StatevectorSampler` and `StatevectorEstimator` for simulator-backed reference implementations of the Qiskit Primitives.

### Defining equivalence relationships

A common task in mapping abstract circuits to physical hardware and optimizing the result is to find equivalence relations that map a gate to a different basis set. Qiskit stores this information in a database class called `EquivalenceLibrary`.

`EquivalenceLibrary`([base])A library providing a one-way mapping of Gates to their equivalent implementations as QuantumCircuits.

Qiskit ships with a large set of predefined equivalence relationships for all of its standard gates. This base library is called `StandardEquivalenceLibrary`, and should be treated as immutable.

#### qiskit.circuit.StandardEquivalenceLibrary

A `EquivalenceLibrary` that stores of all Qiskit’s built-in standard gate relationships. You should not mutate this, but instead either create your own `EquivalenceLibrary` using this one as its `base`, or modify the global-state `SessionEquivalenceLibrary`.

Qiskit also defines a shared global-state object, `SessionEquivalenceLibrary`, which is the default equivalences used by various places in Qiskit, most notably the `BasisTranslator` transpiler pass. You should feel free to add your own equivalences to this using its `add_equivalence()` method, and they will be automatically picked up by default instances of the `BasisTranslator`.

#### qiskit.circuit.SessionEquivalenceLibrary

The default instance of `EquivalenceLibrary`, which will be used by most Qiskit objects if no library is manually specified. You can feel free to add equivalences to this using `add_equivalence()`. It inherits all the built-in rules of `StandardEquivalenceLibrary`.

### Apply Pauli twirling to a circuit

There are two primary types of noise when executing quantum circuits. The first is stochastic, or incoherent, noise that is mainly due to the unwanted interaction between the quantum processor and the external environment in which it resides. The second is known as coherent error, and these errors arise due to imperfect control of a quantum system. This can be unwanted terms in a system Hamiltonian, i.e. incorrect unitary evolution, or errors from incorrect temporal control of the quantum system, which includes things like incorrect pulse-shapes for gates.

Pauli twirling is a quantum error suppression technique that uses randomization to shape coherent error into stochastic errors by combining the results from many random, but logically equivalent circuits, together. Qiskit provides a function to apply Pauli twirling to a given circuit for standard two qubit gates. For more details you can refer to the documentation of the function below:

#### pauli_twirl_2q_gates

`qiskit.circuit.pauli_twirl_2q_gates(circuit, twirling_gate=None, seed=None, num_twirls=None, target=None)`
GitHub
Create copies of a given circuit with Pauli twirling applied around specified two qubit gates.

If you’re running this function with the intent to twirl a circuit to run on hardware this may not be the most efficient way to perform twirling. Especially if the hardware vendor has implemented the `primitives` execution interface with `SamplerV2` and `EstimatorV2` this most likely is not the best way to apply twirling to your circuit and you’ll want to refer to the implementation of `SamplerV2` and/or `EstimatorV2` for the specified hardware vendor.

If the intent of this function is to be run after `transpile()` or `PassManager.run()` the optional `target` argument can be used so that the inserted 1 qubit Pauli gates are synthesized to be compatible with the given `Target` so the output circuit(s) are still compatible.

Parameters

- circuit (QuantumCircuit) – The circuit to twirl

- twirling_gate (None |str|Gate|list[str] |list[Gate]) – The gate to twirl, defaults to None which means twirl all default gates: `CXGate`, `CZGate`, `ECRGate`, and `iSwapGate`. If supplied it can either be a single gate or a list of gates either as either a gate object or its string name. Currently only the names “cx”, “cz”, “ecr”, and “iswap” are supported. If a gate object is provided outside the default gates it must have a matrix defined from its `to_matrix` method for the gate to potentially be twirled. If a valid twirling configuration can’t be computed that particular gate will be silently ignored and not twirled.

- seed (int| None) – An integer seed for the random number generator used internally by this function. If specified this must be between 0 and 18,446,744,073,709,551,615.

- num_twirls (int| None) – The number of twirling circuits to build. This defaults to `None` and will return a single circuit. If it is an integer a list of circuits with num_twirls circuits will be returned.

- target (Target| None) – If specified an `Target` instance to use for running single qubit decomposition as part of the Pauli twirling to optimize and map the pauli gates added to the circuit to the specified target.

Returns

A copy of the given circuit with Pauli twirling applied to each instance of the specified twirling gate.

Return type

QuantumCircuit | list[QuantumCircuit]

## Exceptions

Almost all circuit functions and methods will raise a `CircuitError` when encountering an error that is particular to usage of Qiskit (as opposed to regular typing or indexing problems, which will typically raise the corresponding standard Python error).

### CircuitError

exception`qiskit.circuit.CircuitError(*message)`
GitHub
Bases: `QiskitError`

Base class for errors raised while processing a circuit.

Set the error message.

## Circuit conventions

When constructing circuits out of abstract objects and more concrete matrices, there are several possible conventions around bit-labelling, bit-ordering, and how the abstract tensor product is realized in concrete matrix algebra.

Qiskit’s conventions are:

- in bitstring representations, bits are labelled with the right-most bit in the string called 000 and the left-most bit in the string of nnn bits called n−1n - 1n−1.

- when using integers as bit-specifier indices in circuit-construction functions, the integer is treated as an index into `QuantumCircuit.qubits` (or `clbits`).

- when drawing circuits, we put the lowest-index bits on top.

- in statevector representations, we realize the abstract tensor product as the Kronecker product, and order the arguments to this such that the amplitude of computational-basis state ∣x⟩\lvert x\rangle∣x⟩, where xxx is the bitstring interpreted as an integer, is at location `statevector[x]`.

- when controlling a gate, the control qubit(s) is placed first in the argument list, e.g. in the call `qc.cx(0, 1)`, qubit 0 will be the control and qubit 1 will be the target. Similarly, in the manual call `qc.append(CXGate(), [0, 1])`, qubit 0 will be the control and qubit 1 will be the target.

Let us illustrate these conventions with some examples.

### Bit labelling

Take the circuit:

```
from qiskit import QuantumCircuitqc = QuantumCircuit(5, 5)qc.x(0)qc.x(1)qc.x(4)qc.measure(range(5), range(5))
```

This flips the states of qubits 0, 1 and 4 from ∣0⟩\lvert0\rangle∣0⟩ to ∣1⟩\lvert1\rangle∣1⟩, then measures all qubits nnn into the corresponding clbit nnn using the computational (ZZZ) basis. If simulated noiselessly, the bitstring output from this circuit will be 100111001110011 every time; qubits 0, 1, and 4 are flipped, and the “one” values in the bitstring are in the zeroth, first and fourth digits from the right.

In Qiskit, we would write the qubit state immediately before the measurement in ket-notation shorthand as ∣10011⟩\lvert10011\rangle∣10011⟩. Note that the ket label matches the classical bitstring, and has the numeric binary value of 19.

If we draw this circuit, we will see that Qiskit places the zeroth qubit on the top of the circuit drawing:

```
qc.draw("mpl")
```

### Matrix representations

Statevectors are defined in the convention that for a two-level system, the relationship between abstract representation and matrix representation is such that
α∣0⟩+β∣1⟩↔(αβ)\alpha\lvert0\rangle + \beta\lvert1\rangle
   \leftrightarrow \begin{pmatrix} \alpha \\ \beta \end{pmatrix}α∣0⟩+β∣1⟩↔(αβ​)
where α\alphaα and β\betaβ are complex numbers. We store the statevector as a 1D Numpy `ndarray` with data `sv = [alpha, beta]`, i.e.`sv[0] == alpha` and `sv[1] == beta`; note that the indices into the statevector match the ket labels.

We construct the tensor product of two qubit states in matrix algebra using the Kronecker product, with qubit 0 on the right and qubit 1 on the left, such that the ZZZ basis state ∣x⟩\lvert x\rangle∣x⟩ (where xxx is the integer interpretation of the bitstring) has its non-zero term in the statevector `sv` at `sv[x]`:

```
import numpyfrom qiskit import QuantumCircuitfrom qiskit.quantum_info import Statevectorstate_0 = [1, 0]  # defined representation of |0>state_1 = [0, 1]  # defined representation of |1># Circuit that creates basis state |10011>, where# binary 10011 has the decimal value 19.qc = QuantumCircuit(5)qc.x(0)qc.x(1)qc.x(4)qiskit_sv = Statevector(qc)# List index 'n' corresponds to qubit 'n'.individual_states = [    state_1,    state_1,    state_0,    state_0,    state_1,]# Start from a scalar.manual_sv = [1]for qubit_state in individual_states:    # Each new qubit goes "on the left".    manual_sv = numpy.kron(qubit_state, manual_sv)# Now `qiskit_sv` and `manual_sv` are the same, and:assert manual_sv[19] == 1assert qiskit_sv[19] == 1
```

This feeds through to the matrix representation of operators, and joins with the conventions on bit orders for controlled operators. For example, the matrix form of `CXGate` is:

```
import numpyfrom qiskit.circuit.library import CXGatenumpy.array(CXGate())
```

array⁡(CX)=(1000000100100100)\operatorname{array}(CX) =
    \begin{pmatrix}
        1 & 0 & 0 & 0 \\
        0 & 0 & 0 & 1 \\
        0 & 0 & 1 & 0 \\
        0 & 1 & 0 & 0
    \end{pmatrix}array(CX)=​1000​0001​0010​0100​​
This might be different to other matrix representations you have seen for CXCXCX, but recall that the choice of matrix representation is conventional, and this form matches Qiskit’s conventions of control qubits come first and the tensor product is represented such that there is a correspondence between the index of the “one amplitude” and the bitstring value of a state.

In the case of multiple controls for a gate, such as for `CCXGate`, the `ctrl_state` argument is interpreted as the bitstring value of the control qubits, using the same zero-based labelling conventions. For example, given that the default `ctrl_state` is the all-ones bitstring, we can see that the matrix form of `CCXGate` with `ctrl_state = 1` is the same as if we took the all-ones control-state `CCXGate`, but flipped the value of the higher indexed control qubit on entry and exist to the gate:

```
from qiskit import QuantumCircuitfrom qiskit.quantum_info import Operator# Build the natural representation of `CCX` with the# control qubits being `[0, 1]`, relative to the# bitstring state "01", such that qubit 0 must be in |1># and qubit 1 must be in |0>.  The target qubit is 2.ccx_natural = QuantumCircuit(3)ccx_natural.ccx(0, 1, 2, ctrl_state=1)# Build the same circuit in terms of the all-ones CCX.# Note that we flip _qubit 1_, because that's the one# that differs from the all-ones state.ccx_relative = QuantumCircuit(3)ccx_relative.x(1)ccx_relative.ccx(0, 1, 2)ccx_relative.x(1)assert Operator(ccx_relative) == Operator(ccx_natural)
```

In both these cases, the matrix form of `CCXGate` in `ctrl_state = 1` is:
array⁡(CCX(ctrl_state=1))=(1000000000000100001000000001000000001000010000000000001000000001)\operatorname{array}\bigl(CCX(\text{ctrl\_state}=1)\bigr) =
    \begin{pmatrix}
        1 & 0 & 0 & 0 & 0 & 0 & 0 & 0 \\
        0 & 0 & 0 & 0 & 0 & 1 & 0 & 0 \\
        0 & 0 & 1 & 0 & 0 & 0 & 0 & 0 \\
        0 & 0 & 0 & 1 & 0 & 0 & 0 & 0 \\
        0 & 0 & 0 & 0 & 1 & 0 & 0 & 0 \\
        0 & 1 & 0 & 0 & 0 & 0 & 0 & 0 \\
        0 & 0 & 0 & 0 & 0 & 0 & 1 & 0 \\
        0 & 0 & 0 & 0 & 0 & 0 & 0 & 1
    \end{pmatrix}array(CCX(ctrl_state=1))=​10000000​00000100​00100000​00010000​00001000​01000000​00000010​00000001​​

Was this page helpful?

Report a bug, typo, or request content on GitHub.

On this page

- Circuit concepts and definitions

- API overview of qiskit.circuit

- Representation of circuits in Qiskit

- Bits and registers

- Instruction contexts

- Operations, instructions and gates

- Built-in special instructions

- Real-time classical computation

- Compile-time parametrization

- Control flow in circuits

- Instruction-local annotations

- Investigating commutation relations

- Delayed-resolution scheduling

- Creating custom instructions

- Creating instruction subclasses

- Working with circuit-level objects

- Converting abstract circuits to physical circuits

- Simulating circuits

- Defining equivalence relationships

- Apply Pauli twirling to a circuit

- Exceptions

- CircuitError

- Circuit conventions

- Bit labelling

- Matrix representations

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
