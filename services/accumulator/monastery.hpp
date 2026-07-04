// monastery.hpp — The Template Metaprogramming Monastery.
//
// Behind these walls, the constant 0 is derived a third way: by climbing a
// tower of 500 nested template instantiations and then descending it again,
// entirely at compile time. The compiler performs every step. The binary
// receives a single integer literal: 0. The monks receive nothing, which
// was always the arrangement.
//
// Requires -ftemplate-depth=600 (the tower plus a margin for humility).
#pragma once

namespace monastery {

// The ascent: Peano successors, one instantiation per rung.
template <unsigned N>
struct Ascend {
    static constexpr unsigned long long value = Ascend<N - 1>::value + 1ULL;
};

template <>
struct Ascend<0> {
    static constexpr unsigned long long value = 0ULL;
};

// The descent: predecessors, one instantiation per rung, back to the ground.
template <unsigned N>
struct Descend {
    static constexpr unsigned long long value = Descend<N - 1>::value - 1ULL;
    // Each rung of the descent must equal the matching rung of the ascent's
    // memory of it. The compiler checks 500 of these. It never complains.
    static_assert(Descend<N - 1>::value >= 1ULL, "the descent has gone below ground");
};

template <>
struct Descend<0> {
    static constexpr unsigned long long value = Ascend<500>::value;
};

// The revelation, available before the program even exists:
constexpr unsigned long long compile_time_zero = Descend<500>::value;

static_assert(compile_time_zero == 0ULL,
    "the monastery has miscounted; 500 steps up and 500 steps down "
    "should arrive precisely nowhere");

}  // namespace monastery
