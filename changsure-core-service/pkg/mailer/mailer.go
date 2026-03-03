package mailer

import (
	"crypto/tls"
	"fmt"
	"net/smtp"
	"strings"
)

type Config struct {
	Host     string
	Port     int
	Username string
	Password string
	From     string
	FromName string
}

type Mailer interface {
	SendOTP(to, name, otp string) error
}

type mailer struct {
	cfg Config
}

func New(cfg Config) Mailer {
	return &mailer{cfg: cfg}
}

func (m *mailer) SendOTP(to, name, otp string) error {
	subject := "รหัส OTP สำหรับรีเซ็ตรหัสผ่าน — ChangSure"
	body := buildOTPEmail(name, otp)

	return m.send(to, subject, body)
}

func (m *mailer) send(to, subject, htmlBody string) error {
	addr := fmt.Sprintf("%s:%d", m.cfg.Host, m.cfg.Port)

	auth := smtp.PlainAuth("", m.cfg.Username, m.cfg.Password, m.cfg.Host)

	from := fmt.Sprintf("%s <%s>", m.cfg.FromName, m.cfg.From)
	headers := strings.Join([]string{
		fmt.Sprintf("From: %s", from),
		fmt.Sprintf("To: %s", to),
		fmt.Sprintf("Subject: %s", subject),
		"MIME-Version: 1.0",
		`Content-Type: text/html; charset="UTF-8"`,
	}, "\r\n")

	msg := []byte(headers + "\r\n\r\n" + htmlBody)

	tlsCfg := &tls.Config{
		InsecureSkipVerify: false,
		ServerName:         m.cfg.Host,
	}

	conn, err := tls.Dial("tcp", addr, tlsCfg)
	if err != nil {
		return fmt.Errorf("dial smtp: %w", err)
	}
	defer conn.Close()

	client, err := smtp.NewClient(conn, m.cfg.Host)
	if err != nil {
		return fmt.Errorf("new smtp client: %w", err)
	}
	defer client.Close()

	if err := client.Auth(auth); err != nil {
		return fmt.Errorf("smtp auth: %w", err)
	}
	if err := client.Mail(m.cfg.From); err != nil {
		return fmt.Errorf("smtp mail from: %w", err)
	}
	if err := client.Rcpt(to); err != nil {
		return fmt.Errorf("smtp rcpt to: %w", err)
	}

	w, err := client.Data()
	if err != nil {
		return fmt.Errorf("smtp data: %w", err)
	}
	defer w.Close()

	if _, err := w.Write(msg); err != nil {
		return fmt.Errorf("smtp write: %w", err)
	}

	return nil
}

func buildOTPEmail(name, otp string) string {
	digits := strings.Split(otp, "")
	digitBoxes := ""
	for _, d := range digits {
		digitBoxes += fmt.Sprintf(`
			<td style="width:48px;height:56px;text-align:center;vertical-align:middle;
				background:#f0f4ff;border:2px solid #1a2744;border-radius:8px;
				font-size:28px;font-weight:700;color:#1a2744;font-family:monospace;">
				%s
			</td>
			<td style="width:8px;"></td>`, d)
	}

	return fmt.Sprintf(`<!DOCTYPE html>
<html lang="th">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#f7f5f0;font-family:'Sarabun',sans-serif;">
<table width="100%%" cellpadding="0" cellspacing="0" style="background:#f7f5f0;padding:40px 20px;">
  <tr><td align="center">
    <table width="560" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">
      
      <!-- Header -->
      <tr>
        <td style="background:#1a2744;padding:28px 40px;text-align:center;">
          <span style="font-size:24px;font-weight:700;color:#ffffff;letter-spacing:0.5px;">
            Chang<span style="color:#e85d2f;">Sure</span>
          </span>
          <p style="margin:6px 0 0;color:rgba(255,255,255,0.6);font-size:13px;">ช่างชัวร์ — แพลตฟอร์มบริการออนไลน์</p>
        </td>
      </tr>

      <!-- Body -->
      <tr>
        <td style="padding:40px 40px 32px;">
          <p style="font-size:16px;color:#1a1a1a;margin:0 0 8px;">สวัสดีคุณ <strong>%s</strong>,</p>
          <p style="font-size:15px;color:#555;margin:0 0 28px;line-height:1.7;">
            เราได้รับคำขอรีเซ็ตรหัสผ่านของคุณ กรุณาใช้รหัส OTP ด้านล่างนี้ภายใน <strong style="color:#e85d2f;">5 นาที</strong>
          </p>

          <!-- OTP Boxes -->
          <table cellpadding="0" cellspacing="0" style="margin:0 auto 28px;">
            <tr>%s</tr>
          </table>

          <!-- Warning -->
          <div style="background:#fff8f6;border:1px solid #f5c4b8;border-left:4px solid #e85d2f;border-radius:6px;padding:14px 18px;margin-bottom:24px;">
            <p style="margin:0;font-size:13.5px;color:#8b2500;line-height:1.6;">
              ⚠️ <strong>หากคุณไม่ได้ขอรีเซ็ตรหัสผ่าน</strong> กรุณาละเว้นอีเมลนี้ และรหัสจะหมดอายุโดยอัตโนมัติ
            </p>
          </div>

          <p style="font-size:13px;color:#999;margin:0;line-height:1.6;">
            รหัสนี้ใช้ได้เพียงครั้งเดียวและจะหมดอายุใน 5 นาที<br>
            หากมีปัญหาติดต่อ <a href="mailto:support@changsure.com" style="color:#1a2744;">support@changsure.com</a>
          </p>
        </td>
      </tr>

      <!-- Footer -->
      <tr>
        <td style="background:#f7f5f0;padding:20px 40px;text-align:center;border-top:1px solid #e8e4dc;">
          <p style="margin:0;font-size:12px;color:#aaa;">
            © 2025 ChangSure Co., Ltd. · <a href="#" style="color:#aaa;text-decoration:none;">นโยบายความเป็นส่วนตัว</a>
          </p>
        </td>
      </tr>

    </table>
  </td></tr>
</table>
</body>
</html>`, name, digitBoxes)
}
