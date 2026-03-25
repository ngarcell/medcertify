import UIKit
import PDFKit

@MainActor
struct PDFExporter {

    // MARK: - Public

    static func generateCredentialSummary(credentials: [Credential], profileName: String?) -> Data {
        let pageWidth: CGFloat = 612 // US Letter
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let contentWidth = pageWidth - margin * 2

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let data = renderer.pdfData { context in
            var yPosition: CGFloat = 0

            func startNewPage() {
                context.beginPage()
                yPosition = margin
            }

            func ensureSpace(_ needed: CGFloat) {
                if yPosition + needed > pageHeight - margin {
                    startNewPage()
                }
            }

            // --- Page 1 ---
            startNewPage()

            // Header
            let titleFont = UIFont.systemFont(ofSize: 22, weight: .bold)
            let subtitleFont = UIFont.systemFont(ofSize: 12, weight: .regular)
            let headerFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
            let bodyFont = UIFont.systemFont(ofSize: 11, weight: .regular)
            let boldBodyFont = UIFont.systemFont(ofSize: 11, weight: .semibold)
            let captionFont = UIFont.systemFont(ofSize: 9, weight: .regular)

            let titleColor = UIColor(red: 0.09, green: 0.36, blue: 0.72, alpha: 1) // Medical blue
            let headerColor = UIColor(red: 0.09, green: 0.36, blue: 0.72, alpha: 1)
            let textColor = UIColor.darkText
            let secondaryColor = UIColor.secondaryLabel
            let greenColor = UIColor(red: 0.20, green: 0.66, blue: 0.33, alpha: 1)
            let amberColor = UIColor(red: 0.85, green: 0.55, blue: 0.10, alpha: 1)
            let redColor = UIColor(red: 0.85, green: 0.20, blue: 0.15, alpha: 1)

            // App title
            let titleStr = "MedCertify — Credential Summary"
            titleStr.draw(
                in: CGRect(x: margin, y: yPosition, width: contentWidth, height: 30),
                withAttributes: [.font: titleFont, .foregroundColor: titleColor]
            )
            yPosition += 30

            // Divider
            let dividerPath = UIBezierPath()
            dividerPath.move(to: CGPoint(x: margin, y: yPosition))
            dividerPath.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition))
            titleColor.setStroke()
            dividerPath.lineWidth = 2
            dividerPath.stroke()
            yPosition += 10

            // Profile & date info
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long

            let generatedStr = "Generated: \(dateFormatter.string(from: Date()))"
            generatedStr.draw(
                in: CGRect(x: margin, y: yPosition, width: contentWidth, height: 16),
                withAttributes: [.font: subtitleFont, .foregroundColor: secondaryColor]
            )
            yPosition += 18

            if let name = profileName, !name.isEmpty {
                let profileStr = "Professional: \(name)"
                profileStr.draw(
                    in: CGRect(x: margin, y: yPosition, width: contentWidth, height: 16),
                    withAttributes: [.font: subtitleFont, .foregroundColor: secondaryColor]
                )
                yPosition += 18
            }

            let totalStr = "Total Credentials: \(credentials.count)"
            totalStr.draw(
                in: CGRect(x: margin, y: yPosition, width: contentWidth, height: 16),
                withAttributes: [.font: boldBodyFont, .foregroundColor: textColor]
            )
            yPosition += 24

            // Status summary
            let currentCount = credentials.filter { $0.status == .current }.count
            let expiringCount = credentials.filter { $0.status == .expiringSoon }.count
            let expiredCount = credentials.filter { $0.status == .expired }.count
            let pendingCount = credentials.filter { $0.status == .pending }.count

            func drawStatusBadge(label: String, count: Int, color: UIColor, x: CGFloat) {
                let badgeWidth: CGFloat = (contentWidth - 30) / 4
                let rect = CGRect(x: x, y: yPosition, width: badgeWidth, height: 40)

                // Background
                let bgPath = UIBezierPath(roundedRect: rect, cornerRadius: 8)
                color.withAlphaComponent(0.1).setFill()
                bgPath.fill()

                // Count
                let countStr = "\(count)"
                let countSize = countStr.size(withAttributes: [.font: headerFont, .foregroundColor: color])
                countStr.draw(
                    at: CGPoint(x: x + (badgeWidth - countSize.width) / 2, y: yPosition + 4),
                    withAttributes: [.font: headerFont, .foregroundColor: color]
                )

                // Label
                let labelSize = label.size(withAttributes: [.font: captionFont, .foregroundColor: color])
                label.draw(
                    at: CGPoint(x: x + (badgeWidth - labelSize.width) / 2, y: yPosition + 22),
                    withAttributes: [.font: captionFont, .foregroundColor: color]
                )
            }

            let badgeWidth = (contentWidth - 30) / 4
            drawStatusBadge(label: "Current", count: currentCount, color: greenColor, x: margin)
            drawStatusBadge(label: "Expiring", count: expiringCount, color: amberColor, x: margin + badgeWidth + 10)
            drawStatusBadge(label: "Expired", count: expiredCount, color: redColor, x: margin + (badgeWidth + 10) * 2)
            drawStatusBadge(label: "Pending", count: pendingCount, color: secondaryColor, x: margin + (badgeWidth + 10) * 3)
            yPosition += 54

            // Group credentials by type
            let grouped = Dictionary(grouping: credentials) { $0.credentialType.category }
            let sortedCategories = grouped.keys.sorted()

            for category in sortedCategories {
                guard let items = grouped[category] else { continue }

                ensureSpace(60)

                // Category header
                let catRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: 22)
                let catBg = UIBezierPath(roundedRect: catRect, cornerRadius: 4)
                headerColor.withAlphaComponent(0.08).setFill()
                catBg.fill()

                category.draw(
                    in: CGRect(x: margin + 8, y: yPosition + 3, width: contentWidth - 16, height: 18),
                    withAttributes: [.font: headerFont, .foregroundColor: headerColor]
                )
                yPosition += 28

                // Credentials in this category
                for credential in items {
                    ensureSpace(55)

                    // Name
                    let credName = credential.name.isEmpty ? credential.credentialType.rawValue : credential.name
                    credName.draw(
                        in: CGRect(x: margin + 8, y: yPosition, width: contentWidth * 0.6, height: 15),
                        withAttributes: [.font: boldBodyFont, .foregroundColor: textColor]
                    )

                    // Status badge
                    let statusStr = credential.status.rawValue
                    let statusColor: UIColor = {
                        switch credential.status {
                        case .current: return greenColor
                        case .expiringSoon: return amberColor
                        case .expired: return redColor
                        case .pending: return secondaryColor
                        }
                    }()
                    let statusSize = statusStr.size(withAttributes: [.font: captionFont])
                    let statusX = pageWidth - margin - statusSize.width - 12
                    let statusRect = CGRect(x: statusX - 4, y: yPosition, width: statusSize.width + 8, height: 14)
                    let statusBg = UIBezierPath(roundedRect: statusRect, cornerRadius: 3)
                    statusColor.withAlphaComponent(0.15).setFill()
                    statusBg.fill()
                    statusStr.draw(
                        at: CGPoint(x: statusX, y: yPosition),
                        withAttributes: [.font: captionFont, .foregroundColor: statusColor]
                    )
                    yPosition += 16

                    // Details row
                    var details: [String] = []
                    if !credential.issuingBody.isEmpty {
                        details.append("Issuer: \(credential.issuingBody)")
                    }
                    if let state = credential.state, !state.isEmpty {
                        details.append("State: \(state)")
                    }
                    if let number = credential.credentialNumber, !number.isEmpty {
                        details.append("# \(number)")
                    }

                    if !details.isEmpty {
                        let detailStr = details.joined(separator: "  •  ")
                        detailStr.draw(
                            in: CGRect(x: margin + 8, y: yPosition, width: contentWidth - 16, height: 14),
                            withAttributes: [.font: captionFont, .foregroundColor: secondaryColor]
                        )
                        yPosition += 14
                    }

                    // Dates
                    var dateInfo: [String] = []
                    if let issueDate = credential.issueDate {
                        dateInfo.append("Issued: \(dateFormatter.string(from: issueDate))")
                    }
                    if let expDate = credential.expirationDate {
                        dateInfo.append("Expires: \(dateFormatter.string(from: expDate))")
                    }
                    if let days = credential.daysUntilExpiration {
                        if days > 0 {
                            dateInfo.append("(\(days) days remaining)")
                        } else if days < 0 {
                            dateInfo.append("(\(abs(days)) days overdue)")
                        } else {
                            dateInfo.append("(Expires today)")
                        }
                    }

                    if !dateInfo.isEmpty {
                        let dateStr = dateInfo.joined(separator: "  •  ")
                        dateStr.draw(
                            in: CGRect(x: margin + 8, y: yPosition, width: contentWidth - 16, height: 14),
                            withAttributes: [.font: captionFont, .foregroundColor: secondaryColor]
                        )
                        yPosition += 14
                    }

                    yPosition += 8 // spacing between credentials
                }

                yPosition += 6 // spacing between categories
            }

            // Footer
            ensureSpace(40)
            yPosition += 10
            let footerDivider = UIBezierPath()
            footerDivider.move(to: CGPoint(x: margin, y: yPosition))
            footerDivider.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition))
            UIColor.separator.setStroke()
            footerDivider.lineWidth = 0.5
            footerDivider.stroke()
            yPosition += 8

            let disclaimerStr = "This document is for personal organization only. It is not an official credential verification. Always verify directly with licensing boards."
            disclaimerStr.draw(
                in: CGRect(x: margin, y: yPosition, width: contentWidth, height: 30),
                withAttributes: [.font: captionFont, .foregroundColor: secondaryColor]
            )
            yPosition += 30

            let footerStr = "Generated by MedCertify • \(dateFormatter.string(from: Date()))"
            let footerSize = footerStr.size(withAttributes: [.font: captionFont])
            footerStr.draw(
                at: CGPoint(x: (pageWidth - footerSize.width) / 2, y: yPosition),
                withAttributes: [.font: captionFont, .foregroundColor: secondaryColor]
            )
        }

        return data
    }

    /// Saves PDF to temp directory and returns the file URL for sharing
    static func saveTempPDF(data: Data) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "MedCertify_Summary_\(Date().formatted(.dateTime.year().month().day())).pdf"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to save PDF: \(error)")
            return nil
        }
    }
}
