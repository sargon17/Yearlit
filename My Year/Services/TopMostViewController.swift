import UIKit

@MainActor
func topMostViewController(
  base: UIViewController? = nil
) -> UIViewController? {
  let resolvedBase = base ?? UIApplication.shared.connectedScenes
    .compactMap { ($0 as? UIWindowScene)?.keyWindow }
    .first?.rootViewController

  if let nav = resolvedBase as? UINavigationController {
    return topMostViewController(base: nav.visibleViewController)
  }
  if let tab = resolvedBase as? UITabBarController, let selected = tab.selectedViewController {
    return topMostViewController(base: selected)
  }
  if let presented = resolvedBase?.presentedViewController {
    return topMostViewController(base: presented)
  }
  return resolvedBase
}

private extension UIWindowScene {
  var keyWindow: UIWindow? {
    windows.first(where: { $0.isKeyWindow })
  }
}
