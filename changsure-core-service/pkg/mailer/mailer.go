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
		digitBoxes += fmt.Sprintf(`<td style="
			width:48px;
			height:58px;
			text-align:center;
			vertical-align:middle;
			background:#f8faff;
			border:1.5px solid #c8d8f0;
			border-radius:10px;
			font-size:26px;
			font-weight:500;
			color:#1a4fa0;
			font-family:'SF Mono','Fira Code',monospace;
		">%s</td><td style="width:8px;"></td>`, d)
	}

	return fmt.Sprintf(`<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@700;800&family=Sarabun:wght@300;400;500;600&display=swap" rel="stylesheet">
</head>
<body style="margin:0;padding:0;background:#ffffff;font-family:'Sarabun',sans-serif;">

<table width="100%%" cellpadding="0" cellspacing="0" style="background:#ffffff;padding:56px 24px 64px;">
  <tr><td align="center">

    <!-- Card -->
    <table width="480" cellpadding="0" cellspacing="0" style="
      background:#ffffff;
      border-radius:16px;
      border:1px solid #e8e4de;
      box-shadow:0 2px 12px rgba(0,0,0,0.05);
    ">

      <tr><td style="height:44px;"></td></tr>

      <!-- Logo -->
      <tr>
        <td style="text-align:center;padding:0 48px;">
          <span style="font-size:27px;font-weight:700;letter-spacing:-0.3px;font-family:'Poppins','Segoe UI',sans-serif;">
            <span style="color:#4fb3e8;">Chang</span><span style="color:#1a4fa0;">Sure</span>
          </span>
        </td>
      </tr>

      <!-- Divider -->
      <tr>
        <td style="padding:24px 48px 0;">
          <div style="height:1px;background:#f0ede8;"></div>
        </td>
      </tr>

      <!-- Body -->
      <tr>
        <td style="padding:32px 48px 0;">

          <p style="margin:0 0 6px;font-size:15px;font-weight:500;color:#111111;">
            สวัสดี คุณ %s
          </p>
          <p style="margin:0 0 32px;font-size:14px;color:#777777;line-height:1.85;font-weight:300;">
            เราได้รับคำขอรีเซ็ตรหัสผ่านของคุณ<br>
            กรุณาใช้รหัส OTP ด้านล่างเพื่อดำเนินการต่อ
          </p>

          <!-- OTP Boxes -->
          <table cellpadding="0" cellspacing="0" style="margin:0 0 32px;">
            <tr>%s</tr>
          </table>

          <!-- Expiry -->
          <p style="margin:0 0 8px;font-size:13px;font-weight:500;color:#1a4fa0;">
            รหัสนี้มีอายุการใช้งาน 5 นาที
          </p>

          <!-- Note -->
          <p style="margin:0;font-size:13px;color:#aaaaaa;line-height:1.85;font-weight:300;">
            หากคุณไม่ได้ร้องขอรหัสนี้ กรุณาเพิกเฉยต่ออีเมลฉบับนี้
          </p>

        </td>
      </tr>

      <!-- Sign-off -->
      <tr>
        <td style="padding:36px 48px 40px;">
          <p style="margin:0;font-size:13px;color:#cccccc;font-weight:300;">
            ChangSure Team
          </p>
        </td>
      </tr>

    </table>

    <!-- Footer -->
    <p style="margin:20px 0 0;font-size:11px;color:#b8b0a4;text-align:center;">
      © 2025 ChangSure Co., Ltd.
    </p>

  </td></tr>
</table>

</body>
</html>`, name, digitBoxes)
}