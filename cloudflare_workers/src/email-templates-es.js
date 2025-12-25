/**
 * Spanish Email Templates
 * Plantillas de correo electrónico en español
 */

export function getSpanishActivationEmail(code, tier) {
  return `
    <!DOCTYPE html>
    <html lang="es">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Helvetica', 'Arial', sans-serif; line-height: 1.6; background: #0f0f1e; margin: 0; }
        .email-wrapper { background: #0f0f1e; padding: 40px 20px; }
        .email-container { max-width: 600px; margin: 0 auto; background: #1a1b2e; border-radius: 8px; overflow: hidden; }

        /* Header */
        .header { background: #1a1b2e; padding: 40px 30px; text-align: center; border-bottom: 1px solid rgba(255,255,255,0.1); }
        .logo { width: 80px; height: 80px; margin: 0 auto 20px; }
        .header-title { color: #ffffff; font-size: 28px; font-weight: 600; margin: 0 0 8px 0; }
        .header-subtitle { color: rgba(255,255,255,0.6); font-size: 16px; font-weight: 400; }

        /* Content */
        .content { padding: 40px 30px; background: #1a1b2e; }
        .greeting { font-size: 18px; color: #ffffff; margin-bottom: 16px; font-weight: 400; }
        .message { color: rgba(255,255,255,0.8); font-size: 15px; margin-bottom: 24px; line-height: 1.6; }

        /* Activation Code - Yellow CTA style */
        .code-section { background: #FDB022; border-radius: 8px; padding: 32px 24px; text-align: center; margin: 32px 0; }
        .code-label { color: #1a1b2e; font-size: 12px; text-transform: uppercase; letter-spacing: 1.5px; font-weight: 600; margin-bottom: 12px; }
        .activation-code { font-size: 36px; font-weight: 700; color: #1a1b2e; letter-spacing: 4px; font-family: 'Courier New', monospace; }

        /* Instructions */
        .instructions { background: rgba(255,255,255,0.05); border-radius: 8px; padding: 24px; margin: 32px 0; }
        .instructions-title { color: #ffffff; font-size: 16px; font-weight: 600; margin-bottom: 16px; }
        .instructions ol { margin-left: 20px; color: rgba(255,255,255,0.8); padding-left: 0; }
        .instructions li { margin: 12px 0; font-size: 14px; line-height: 1.6; }
        .instructions strong { color: #FDB022; font-weight: 600; }

        /* Tip Box */
        .tip-box { background: rgba(253,176,34,0.1); border: 1px solid rgba(253,176,34,0.3); border-radius: 8px; padding: 20px; margin: 24px 0; }
        .tip-text { color: rgba(255,255,255,0.9); font-size: 14px; line-height: 1.6; display: block; }
        .tip-text strong { color: #FDB022; }

        /* Footer */
        .footer { background: #0f0f1e; padding: 32px 30px; text-align: center; border-top: 1px solid rgba(255,255,255,0.1); }
        .footer-text { color: rgba(255,255,255,0.5); font-size: 13px; line-height: 1.8; }
        .contact-link { color: #FDB022; text-decoration: none; font-weight: 500; }

        .divider { height: 1px; background: rgba(255,255,255,0.1); margin: 32px 0; }

        @media only screen and (max-width: 600px) {
          .email-wrapper { padding: 20px 10px; }
          .header { padding: 32px 24px; }
          .content { padding: 32px 24px; }
          .header-title { font-size: 24px; }
          .activation-code { font-size: 28px; letter-spacing: 3px; }
          .logo { width: 60px; height: 60px; }
        }
      </style>
    </head>
    <body>
      <div class="email-wrapper">
        <div class="email-container">
          <!-- Header -->
          <div class="header">
            <svg class="logo" viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
              <!-- Sunrise -->
              <g stroke="#FDB022" stroke-width="3" fill="none">
                <path d="M 40 120 Q 100 60 160 120" stroke-width="4"/>
                <line x1="100" y1="70" x2="100" y2="50"/>
                <line x1="70" y1="80" x2="60" y2="65"/>
                <line x1="130" y1="80" x2="140" y2="65"/>
                <line x1="50" y1="100" x2="35" y2="95"/>
                <line x1="150" y1="100" x2="165" y2="95"/>
              </g>
              <!-- Open Bible -->
              <g stroke="#FDB022" stroke-width="2" fill="none">
                <path d="M 60 150 L 100 140 L 140 150 L 140 180 L 100 170 L 60 180 Z"/>
                <line x1="100" y1="140" x2="100" y2="170"/>
                <line x1="70" y1="155" x2="90" y2="152"/>
                <line x1="110" y1="152" x2="130" y2="155"/>
              </g>
            </svg>
            <h1 class="header-title">¡Suscripción Activada!</h1>
            <p class="header-subtitle">Bienvenido a Everyday Christian Premium</p>
          </div>

          <!-- Content -->
          <div class="content">
            <p class="greeting">Gracias por suscribirte</p>
            <p class="message">
              Tu viaje de fe está a punto de ser aún más enriquecedor con acceso ilimitado
              a orientación espiritual y apoyo impulsado por IA.
            </p>

            <!-- Activation Code -->
            <div class="code-section">
              <p class="code-label">Tu Código de Activación</p>
              <div class="activation-code">${code}</div>
            </div>

            <!-- Instructions -->
            <div class="instructions">
              <div class="instructions-title">Cómo Activar</div>
              <ol>
                <li>Abre la aplicación <strong>Everyday Christian</strong></li>
                <li>Ve a <strong>Configuración</strong> → <strong>Activar Premium</strong></li>
                <li>Ingresa el código: <strong>${code}</strong></li>
                <li>Comienza a usar tus <strong>150 mensajes mensuales</strong></li>
              </ol>
            </div>

            <!-- Important Tip -->
            <div class="tip-box">
              <span class="tip-text">
                <strong>Importante:</strong> Guarda este correo. Necesitarás este código
                para activar en nuevos dispositivos. Un código funciona en un dispositivo a la vez.
              </span>
            </div>

            <div class="divider"></div>

            <p class="message" style="text-align: center; color: rgba(255,255,255,0.5); font-size: 14px;">
              Que Dios bendiga tu caminar diario con Él
            </p>
          </div>

          <!-- Footer -->
          <div class="footer">
            <p class="footer-text">
              ¿Preguntas o necesitas ayuda?<br>
              Envíanos un correo a <a href="mailto:connect@everydaychristian.app" class="contact-link">connect@everydaychristian.app</a>
            </p>
            <p class="footer-text" style="margin-top: 16px; font-size: 12px;">
              © ${new Date().getFullYear()} Everyday Christian. Todos los derechos reservados.
            </p>
          </div>
        </div>
      </div>
    </body>
    </html>
  `;
}

export function getSpanishTrialEndingEmail(code, daysLeft) {
  return `
    <!DOCTYPE html>
    <html lang="es">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        /* Same styles as activation email */
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Helvetica', 'Arial', sans-serif; line-height: 1.6; background: #0f0f1e; margin: 0; }
        .email-wrapper { background: #0f0f1e; padding: 40px 20px; }
        .email-container { max-width: 600px; margin: 0 auto; background: #1a1b2e; border-radius: 8px; overflow: hidden; }
        .header { background: #1a1b2e; padding: 40px 30px; text-align: center; border-bottom: 1px solid rgba(255,255,255,0.1); }
        .logo { width: 80px; height: 80px; margin: 0 auto 20px; }
        .header-title { color: #ffffff; font-size: 28px; font-weight: 600; margin: 0 0 8px 0; }
        .header-subtitle { color: rgba(255,255,255,0.6); font-size: 16px; font-weight: 400; }
        .content { padding: 40px 30px; background: #1a1b2e; }
        .greeting { font-size: 18px; color: #ffffff; margin-bottom: 16px; font-weight: 400; }
        .message { color: rgba(255,255,255,0.8); font-size: 15px; margin-bottom: 24px; line-height: 1.6; }
        .footer { background: #0f0f1e; padding: 32px 30px; text-align: center; border-top: 1px solid rgba(255,255,255,0.1); }
        .footer-text { color: rgba(255,255,255,0.5); font-size: 13px; line-height: 1.8; }
        .contact-link { color: #FDB022; text-decoration: none; font-weight: 500; }
      </style>
    </head>
    <body>
      <div class="email-wrapper">
        <div class="email-container">
          <div class="header">
            <h1 class="header-title">Tu Prueba Termina Pronto</h1>
            <p class="header-subtitle">Quedan ${daysLeft} días de tu prueba gratuita</p>
          </div>
          <div class="content">
            <p class="greeting">Hola</p>
            <p class="message">
              Tu prueba gratuita de 3 días de Everyday Christian Premium terminará en ${daysLeft} día(s).
              Después de eso, tu suscripción comenzará automáticamente.
            </p>
            <p class="message">
              Si deseas cancelar, puedes hacerlo en cualquier momento desde la aplicación.
            </p>
          </div>
          <div class="footer">
            <p class="footer-text">
              © ${new Date().getFullYear()} Everyday Christian. Todos los derechos reservados.
            </p>
          </div>
        </div>
      </div>
    </body>
    </html>
  `;
}
