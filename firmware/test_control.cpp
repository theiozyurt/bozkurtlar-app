#include <cassert>
#include "bozkurtlar/control_logic.h"
int main() {
  assert(!nextPumpState(false, 699, true, 700, 650));
  assert(nextPumpState(false, 700, true, 700, 650));
  assert(nextPumpState(true, 680, true, 700, 650));
  assert(!nextPumpState(true, 650, true, 700, 650));
  assert(nextPumpState(false, 600, false, 600, 750));
  assert(nextPumpState(true, 700, false, 600, 750));
  assert(!nextPumpState(true, 750, false, 600, 750));
}
