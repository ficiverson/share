# Plan MVP 2 — Share App

Features delivered en MVP 1 y que quedan para la siguiente iteración.

---

## Funcionalidades pendientes

### Gastos

- **Detalle de un gasto** — pantalla individual que muestra descripción, importe, pagador, fecha, categoría, notas y reparto entre miembros.
- **Split personalizado** — al crear/editar un gasto, permitir indicar manualmente cuánto paga cada miembro en lugar del reparto igual automático.
- **Adjuntar foto del ticket** — subir imagen desde cámara o galería y asociarla al gasto (Firebase Storage).
- **Filtrar/buscar gastos** — barra de búsqueda por descripción, categoría o rango de fechas dentro de la lista de gastos.
- **Exportar gastos a CSV** — generar y compartir un fichero CSV con todos los gastos del grupo (inverso a la importación de Splitwise).

### Grupos

- **Editar nombre y moneda del grupo** — formulario de edición accesible desde el detalle del grupo.
- **Borrar un grupo** — actualmente solo es posible salir; el creador debería poder eliminar el grupo completo (gastos + liquidaciones + documento).
- **Roles de miembro** — distinguir entre administradores (pueden borrar gastos de otros) y miembros normales.

### Balance y liquidaciones

- **Gráficas de gasto** — gráfica por categoría o por mes para visualizar en qué se gasta más.
- **Historial de liquidaciones** — pantalla que lista los pagos "settle up" ya realizados, con fecha e importes.
- **Liquidaciones parciales** — permitir liquidar solo parte de la deuda en lugar de siempre el total.

### UX y plataforma

- **Dark mode** — respetar el tema del sistema.
- **Notificaciones push** — avisar al usuario cuando alguien añade un gasto al grupo (Firebase Cloud Messaging).
- **Soporte offline** — usar la caché local de Firestore para que la app funcione sin conexión y sincronice al recuperarla.
- **Editar nombre de grupo y moneda** — formulario accesible desde la pantalla de detalle del grupo.

### Calidad y deuda técnica

- **Tests unitarios** — tests del cálculo de balances, la lógica de importación de CSV y los casos de uso principales.
- **Tests de integración** — flujo completo (login → crear grupo → añadir gasto → ver balance) usando Firestore emulador.
- **CI/CD** — pipeline de GitHub Actions que ejecute los tests en cada PR.
