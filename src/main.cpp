import xieite;

#include <concepts>

using List = xieite::types::List<float, bool, char, int, long>;

int main() {
    static_assert(!std::same_as<int, List::At<3>>);
}
