import SwiftUI

func percentile(_ values: [Int], p: Double) -> Double {
  let s = values.sorted()
  if s.isEmpty { return 1 }
  let pos = max(0, min(Double(s.count - 1), p * Double(s.count - 1)))
  let lo = Int(floor(pos))
  let hi = Int(ceil(pos))
  if lo == hi { return Double(s[lo]) }
  let w = pos - Double(lo)
  return Double(s[lo]) * (1 - w) + Double(s[hi]) * w
}
