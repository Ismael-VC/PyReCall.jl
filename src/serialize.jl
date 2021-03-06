const _pickle = PyNULL()

pickle() = _pickle.o == C_NULL ? copy!(_pickle, pyimport(PyReCall.pyversion.major ≥ 3 ? "pickle" : "cPickle")) : _pickle

function Base.serialize(s::AbstractSerializer, pyo::PyObject)
    Base.serialize_type(s, PyObject)
    if pyo.o == C_NULL
        serialize(s, pyo.o)
    else
        b = PyBuffer(PyReCall(pickle()["dumps"], PyObject, pyo))
        serialize(s, unsafe_wrap(Array, Ptr{UInt8}(pointer(b)), sizeof(b)))
    end
end

pybytes(b) = PyObject(@pycheckn ccall(@pysym(PyString_FromStringAndSize),
                                      PyPtr, (Ptr{UInt8}, Int),
                                      b, sizeof(b)))

function Base.deserialize(s::AbstractSerializer, t::Type{PyObject})
    b = deserialize(s)
    if isa(b, PyPtr)
        @assert b == C_NULL
        return PyNULL()
    else
        return PyReCall(pickle()["loads"], PyObject, pybytes(b))
    end
end
