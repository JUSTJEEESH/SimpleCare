import UIKit
import SwiftData

@MainActor
final class PDFExportService {
    nonisolated(unsafe) static let shared = PDFExportService()

    private init() {}

    func generateReport(
        userName: String,
        medications: [Medication],
        logs: [MedicationLog],
        appointments: [Appointment],
        notes: [HealthNote],
        days: Int = 30
    ) -> Data {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50

        let pdfRenderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        )

        let data = pdfRenderer.pdfData { context in
            var yOffset: CGFloat = 0

            func newPage() {
                context.beginPage()
                yOffset = margin
            }

            func checkPageBreak(_ needed: CGFloat) {
                if yOffset + needed > pageHeight - margin {
                    newPage()
                }
            }

            func drawText(_ text: String, font: UIFont, color: UIColor = .darkText, x: CGFloat = margin, maxWidth: CGFloat? = nil) {
                let width = maxWidth ?? (pageWidth - 2 * margin)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 4

                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color,
                    .paragraphStyle: paragraphStyle
                ]

                let boundingRect = (text as NSString).boundingRect(
                    with: CGSize(width: width, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attributes,
                    context: nil
                )

                checkPageBreak(boundingRect.height + 8)

                (text as NSString).draw(
                    in: CGRect(x: x, y: yOffset, width: width, height: boundingRect.height),
                    withAttributes: attributes
                )
                yOffset += boundingRect.height + 8
            }

            func drawSeparator() {
                checkPageBreak(20)
                let path = UIBezierPath()
                path.move(to: CGPoint(x: margin, y: yOffset + 8))
                path.addLine(to: CGPoint(x: pageWidth - margin, y: yOffset + 8))
                UIColor.lightGray.setStroke()
                path.lineWidth = 0.5
                path.stroke()
                yOffset += 20
            }

            // ---- Page 1: Header ----
            newPage()

            // Title
            drawText("Simple Care", font: .systemFont(ofSize: 24, weight: .bold), color: UIColor(red: 0.45, green: 0.62, blue: 0.78, alpha: 1.0))

            drawText("Health Report", font: .systemFont(ofSize: 18, weight: .semibold))
            yOffset += 4

            // Patient info
            if !userName.isEmpty {
                drawText("Prepared for: \(userName)", font: .systemFont(ofSize: 13, weight: .regular), color: .darkGray)
            }

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            drawText("Report date: \(dateFormatter.string(from: Date()))", font: .systemFont(ofSize: 13, weight: .regular), color: .darkGray)
            drawText("Period: Last \(days) days", font: .systemFont(ofSize: 13, weight: .regular), color: .darkGray)

            drawSeparator()

            // ---- Medications Section ----
            drawText("Current Medications", font: .systemFont(ofSize: 16, weight: .bold))
            yOffset += 4

            if medications.isEmpty {
                drawText("No medications recorded.", font: .systemFont(ofSize: 12), color: .gray)
            } else {
                let timeFormatter = DateFormatter()
                timeFormatter.timeStyle = .short

                for med in medications {
                    checkPageBreak(50)
                    drawText("\(med.name)", font: .systemFont(ofSize: 13, weight: .semibold))
                    if !med.dosage.isEmpty {
                        drawText("  Dosage: \(med.dosage)", font: .systemFont(ofSize: 12), color: .darkGray)
                    }
                    let times = med.scheduleTimes.map { timeFormatter.string(from: $0) }.joined(separator: ", ")
                    if !times.isEmpty {
                        drawText("  Schedule: \(times)", font: .systemFont(ofSize: 12), color: .darkGray)
                    }
                    if !med.notes.isEmpty {
                        drawText("  Notes: \(med.notes)", font: .systemFont(ofSize: 12), color: .darkGray)
                    }
                    yOffset += 4
                }
            }

            drawSeparator()

            // ---- Medication Adherence ----
            drawText("Medication Adherence (Last \(days) Days)", font: .systemFont(ofSize: 16, weight: .bold))
            yOffset += 4

            let takenCount = logs.filter { $0.logStatus == .taken }.count
            let skippedCount = logs.filter { $0.logStatus == .skipped }.count
            let totalLogs = logs.count

            if totalLogs > 0 {
                let adherenceRate = totalLogs > 0 ? Int(Double(takenCount) / Double(totalLogs) * 100) : 0
                drawText("Total scheduled: \(totalLogs)", font: .systemFont(ofSize: 12), color: .darkGray)
                drawText("Taken: \(takenCount)  |  Skipped: \(skippedCount)", font: .systemFont(ofSize: 12), color: .darkGray)
                drawText("Adherence rate: \(adherenceRate)%", font: .systemFont(ofSize: 13, weight: .semibold))
            } else {
                drawText("No medication logs in this period.", font: .systemFont(ofSize: 12), color: .gray)
            }

            drawSeparator()

            // ---- Appointments ----
            drawText("Appointments", font: .systemFont(ofSize: 16, weight: .bold))
            yOffset += 4

            let recentAppointments = appointments.filter {
                $0.dateTime >= Calendar.current.date(byAdding: .day, value: -days, to: Date())! ||
                $0.dateTime >= Date()
            }

            if recentAppointments.isEmpty {
                drawText("No appointments recorded.", font: .systemFont(ofSize: 12), color: .gray)
            } else {
                let aptFormatter = DateFormatter()
                aptFormatter.dateStyle = .medium
                aptFormatter.timeStyle = .short

                for apt in recentAppointments.sorted(by: { $0.dateTime < $1.dateTime }) {
                    checkPageBreak(40)
                    let title = apt.title.isEmpty ? apt.doctorName : "\(apt.title) — \(apt.doctorName)"
                    drawText(title, font: .systemFont(ofSize: 13, weight: .semibold))
                    drawText("  \(aptFormatter.string(from: apt.dateTime))", font: .systemFont(ofSize: 12), color: .darkGray)
                    if !apt.location.isEmpty {
                        drawText("  Location: \(apt.location)", font: .systemFont(ofSize: 12), color: .darkGray)
                    }
                    yOffset += 4
                }
            }

            drawSeparator()

            // ---- Health Notes ----
            drawText("Health Notes", font: .systemFont(ofSize: 16, weight: .bold))
            yOffset += 4

            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
            let recentNotes = notes.filter { $0.createdAt >= cutoffDate }

            if recentNotes.isEmpty {
                drawText("No health notes in this period.", font: .systemFont(ofSize: 12), color: .gray)
            } else {
                let noteFormatter = DateFormatter()
                noteFormatter.dateStyle = .medium
                noteFormatter.timeStyle = .short

                for note in recentNotes.sorted(by: { $0.createdAt > $1.createdAt }) {
                    checkPageBreak(40)
                    drawText(noteFormatter.string(from: note.createdAt), font: .systemFont(ofSize: 11, weight: .semibold), color: .darkGray)
                    drawText(note.content, font: .systemFont(ofSize: 12))
                    yOffset += 6
                }
            }

            // Footer
            drawSeparator()
            drawText(
                "Generated by Simple Care — This is not medical advice. For informational purposes only.",
                font: .systemFont(ofSize: 10),
                color: .lightGray
            )
        }

        return data
    }
}
