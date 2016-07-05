//
//  BugShaker.swift
//  Pods
//
//  Created by Dan Trenz on 12/10/15.
//

import UIKit
import MessageUI
import Device

public class BugShaker {
  
  /// Enable or disable shake detection
  public static var enabled = true

  struct Config {
    static var recipients: [String]?
    static var subject: String?
    static var body: String?
  }

  // MARK: - Configuration

  /**
  Set bug report email recipient(s), custom subject line and body.

  - Parameters:
    - recipients: List of email addresses to which the report will be sent.
    - subject:      Custom subject line to use for the report email.
    - body:         Custom email body (plain text).
  */
  public class func configure(to recipients: [String]!, subject: String?, body: String?) {
    Config.recipients = recipients
    Config.subject = subject
    Config.body = body
  }
  
  /**
   Set bug report email recipient(s) & custom subject line.
   Convenience method for `configure(to:, subject:, body:)` for use when not
   specifying custom body text.
   
   - Parameters:
     - recipients: List of email addresses to which the report will be sent.
     - subject:      Custom subject line to use for the report email.
   */
  public class func configure(to recipients: [String]!, subject: String?) {
      configure(to: recipients, subject: subject, body: nil)
  }

}

extension UIViewController: MFMailComposeViewControllerDelegate {

  // MARK: - UIResponder

  override public func canBecomeFirstResponder() -> Bool {
    return true
  }

  override public func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
    if motion == .MotionShake && BugShaker.enabled {
      let cachedScreenshot = captureScreenshot()

      presentReportPrompt({ (action) -> Void in
        self.presentReportComposeView(cachedScreenshot)
      })
    }
  }

  // MARK: - Alert

  func presentReportPrompt(reportActionHandler: (UIAlertAction) -> Void) {
    let actionSheet = UIAlertController(
      title: "Shake detected!",
      message: "Would you like to report a bug?",
      preferredStyle: .ActionSheet
    )

    let reportAction = UIAlertAction(title: "Report A Bug", style: .Default, handler: reportActionHandler)
    let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { _ in }

    actionSheet.addAction(reportAction)
    actionSheet.addAction(cancelAction)

    presentViewController(actionSheet, animated: true, completion: nil)
  }


  // MARK: - Report methods

  /**
  Take a screenshot for the current screen state.

  - returns: Screenshot image.
  */
  func captureScreenshot() -> UIImage? {
    var screenshot: UIImage? = nil

    if let layer = UIApplication.sharedApplication().keyWindow?.layer {
      let scale = UIScreen.mainScreen().scale

      UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale);

      if let context = UIGraphicsGetCurrentContext() {
        layer.renderInContext(context)
      }

      screenshot = UIGraphicsGetImageFromCurrentImageContext()

      UIGraphicsEndImageContext()
    }

    return screenshot;
  }

    /*
        Device statistics to be included in report body
        ex:
            My Device: iPhone6s
            App Version: 1.0.1
            iOS Version: 9.3
            Time Stamp: 2016-06-24T12:00:00 UTC
    */
    func capturedDeviceStatistics() -> String {
        let device           = UIDevice.currentDevice()

        let formatter        = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss 'UTC'"
        formatter.timeZone   = NSTimeZone(forSecondsFromGMT: 0)
        formatter.locale     = NSLocale(localeIdentifier: "en_US_POSIX")
        let timestamp        = formatter.stringFromDate(NSDate())

        return "My Device: \(Device.version())\r\n"
            + "App Version: \(NSBundle.mainBundle().appVersion)\r\n"
            + "iOS Version: \(device.systemVersion)\r\n"
            + "Time Stamp: \(timestamp)\r\n"
            + "-------------------\r\n"
    }

  /**
   Present the user with a mail compose view with the recipient(s), subject line and body
   pre-populated, and the screenshot attached.

   - parameter screenshot: The screenshot to attach to the report.
   */
  func presentReportComposeView(screenshot: UIImage?) {
    if MFMailComposeViewController.canSendMail() {
      let mailComposer = MFMailComposeViewController()

      guard let toRecipients = BugShaker.Config.recipients else {
        print("BugShaker – Error: No recipients provided. Make sure that BugShaker.configure() is called.")
        return
      }

      let deviceStatistics = capturedDeviceStatistics()

      mailComposer.setToRecipients(toRecipients)
      mailComposer.setSubject(BugShaker.Config.subject ?? "Bug Report")
      mailComposer.setMessageBody(deviceStatistics + (BugShaker.Config.body ?? ""), isHTML: false)
      mailComposer.mailComposeDelegate = self

      if let screenshot = screenshot, let screenshotJPEG = UIImageJPEGRepresentation(screenshot, CGFloat(1.0)) {
        mailComposer.addAttachmentData(screenshotJPEG, mimeType: "image/jpeg", fileName: "screenshot.jpeg")
      }

      presentViewController(mailComposer, animated: true, completion: nil)
    }
  }

  // MARK: - MFMailComposeViewControllerDelegate

  public func mailComposeController(controller: MFMailComposeViewController,
                                    result: MFMailComposeResult,
                                    error: NSError?) {
    if let error = error {
      print("BugShaker – Error: \(error)")
    }

    switch result {
    case MFMailComposeResultFailed:
      print("BugShaker – Bug report send failed.")
      break;

    case MFMailComposeResultSent:
      print("BugShaker – Bug report sent!")
      break;

    default:
      // noop
      break;
    }

    dismissViewControllerAnimated(true, completion: nil)
  }

}
