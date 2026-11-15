// Copyright (c) 2026 Stanley Chege Thuita (practice file, not for upstream)
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.
//
// SPOILER: reference solution for Stage 13, Exercise 4.
// Open it only after ./check_13.sh unit passes, or after 3 honest attempts.
// Works on 29.x (f490f5562d) and master (e75b76b12c): it uses only
// src/serialize.h, src/streams.h and BasicTestingSetup, which exist on both.

#include <serialize.h>
#include <streams.h>
#include <test/util/setup_common.h>

#include <cstddef>
#include <cstdint>
#include <ios>
#include <limits>
#include <string_view>
#include <utility>
#include <vector>

#include <boost/test/unit_test.hpp>

BOOST_FIXTURE_TEST_SUITE(compactsize_boundary_tests, BasicTestingSetup)

namespace {
// Each value next to the size GetSizeOfCompactSize must report for it.
const std::vector<std::pair<uint64_t, unsigned int>> BOUNDARIES{
    {0, 1},
    {252, 1},                                  // largest 1-byte value
    {253, 3},                                  // smallest value that needs the 0xfd marker
    {0xffff, 3},                               // largest 3-byte value
    {0x10000, 5},                              // smallest 0xfe value
    {0xffffffff, 5},                           // largest 5-byte value
    {0x100000000, 9},                          // smallest 0xff value
    {std::numeric_limits<uint64_t>::max(), 9},
};

bool IsSizeTooLarge(const std::ios_base::failure& e)
{
    return std::string_view{e.what()}.find("size too large") != std::string_view::npos;
}
} // namespace

BOOST_AUTO_TEST_CASE(size_boundaries)
{
    static_assert(GetSizeOfCompactSize(252) == 1, "GetSizeOfCompactSize must be usable at compile time");
    for (const auto& [value, expected_size] : BOUNDARIES) {
        BOOST_CHECK_EQUAL(GetSizeOfCompactSize(value), expected_size);
    }
}

BOOST_AUTO_TEST_CASE(written_length_matches_size)
{
    for (const auto& [value, expected_size] : BOUNDARIES) {
        DataStream ss{};
        WriteCompactSize(ss, value);
        BOOST_CHECK_EQUAL(ss.size(), size_t{expected_size});
        if (expected_size == 3) BOOST_CHECK(ss[0] == std::byte{0xfd});
        if (expected_size == 5) BOOST_CHECK(ss[0] == std::byte{0xfe});
        if (expected_size == 9) BOOST_CHECK(ss[0] == std::byte{0xff});
    }
}

BOOST_AUTO_TEST_CASE(round_trip_without_range_check)
{
    for (const auto& [value, expected_size] : BOUNDARIES) {
        DataStream ss{};
        WriteCompactSize(ss, value);
        BOOST_CHECK_EQUAL(ReadCompactSize(ss, /*range_check=*/false), value);
        BOOST_CHECK(ss.empty());
    }
}

BOOST_AUTO_TEST_CASE(range_check_limits)
{
    {
        DataStream ss{};
        WriteCompactSize(ss, MAX_SIZE);
        BOOST_CHECK_EQUAL(ReadCompactSize(ss), MAX_SIZE);
    }
    {
        DataStream ss{};
        WriteCompactSize(ss, MAX_SIZE + 1);
        BOOST_CHECK_EXCEPTION(ReadCompactSize(ss), std::ios_base::failure, IsSizeTooLarge);
    }
}

BOOST_AUTO_TEST_SUITE_END()
