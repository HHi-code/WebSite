import { Controller } from "@hotwired/stimulus"

const DRAG_THRESHOLD = 6

// Перетаскивание карточек элементов между рангами тирлиста.
// Работает через Pointer Events, поэтому поддерживает и мышь, и сенсорные экраны.
export default class extends Controller {
  static targets = ["zone", "status", "retry", "deleteConfirm", "importOverlay", "importDialog"]
  static values = { url: String }

  connect() {
    this.pendingDrag = null
    this.dragCard = null
    this.ghost = null
    this.activeZone = null
    this.saving = false
    this.dirty = false
    this.statusTimer = null
    this.pendingDeleteId = null

    this.onPointerMove = this.onPointerMove.bind(this)
    this.onPointerUp = this.onPointerUp.bind(this)
  }

  disconnect() {
    this.detachWindowListeners()
    this.removeGhost()
    clearTimeout(this.statusTimer)
    this.hideDeleteConfirm()
  }

  // ===== Начало перетаскивания =====

  startDrag(event) {
    if (event.button !== undefined && event.button !== 0) return

    const card = event.target.closest('[data-tier-list-target="card"]')
    if (!card) return

    this.pendingDrag = {
      card,
      pointerId: event.pointerId,
      startX: event.clientX,
      startY: event.clientY,
      started: false,
      offsetX: 0,
      offsetY: 0
    }
    this.attachWindowListeners()
  }

  preventNativeDrag(event) {
    event.preventDefault()
  }

  // Остановка всплытия клика (чтобы кнопка внутри карточки не начинала перетаскивание)
  stopPropagation(event) {
    event.stopPropagation()
  }

  attachWindowListeners() {
    window.addEventListener("pointermove", this.onPointerMove, { passive: false })
    window.addEventListener("pointerup", this.onPointerUp)
    window.addEventListener("pointercancel", this.onPointerUp)
  }

  detachWindowListeners() {
    window.removeEventListener("pointermove", this.onPointerMove)
    window.removeEventListener("pointerup", this.onPointerUp)
    window.removeEventListener("pointercancel", this.onPointerUp)
  }

  onPointerMove(event) {
    const pending = this.pendingDrag
    if (!pending || event.pointerId !== pending.pointerId) return

    if (!pending.started) {
      const distance = Math.hypot(event.clientX - pending.startX, event.clientY - pending.startY)
      if (distance < DRAG_THRESHOLD) return
      this.beginDrag(pending, event)
    }

    event.preventDefault()
    this.moveGhost(event.clientX, event.clientY)
    this.updateDropTarget(event.clientX, event.clientY)
  }

  onPointerUp(event) {
    const pending = this.pendingDrag
    if (!pending || event.pointerId !== pending.pointerId) return

    this.detachWindowListeners()

    if (pending.started) {
      this.finishDrag()
    }

    this.pendingDrag = null
  }

  beginDrag(pending, event) {
    pending.started = true
    const card = pending.card
    const rect = card.getBoundingClientRect()

    pending.offsetX = event.clientX - rect.left
    pending.offsetY = event.clientY - rect.top

    const ghost = card.cloneNode(true)
    ghost.classList.add("tier-card--ghost")
    ghost.classList.remove("tier-card--dragging")
    ghost.removeAttribute("data-tier-list-target")
    ghost.style.width = `${rect.width}px`
    ghost.style.height = `${rect.height}px`
    ghost.setAttribute("aria-hidden", "true")
    document.body.appendChild(ghost)

    this.ghost = ghost
    this.dragCard = card
    this.dragOffsetX = pending.offsetX
    this.dragOffsetY = pending.offsetY

    card.classList.add("tier-card--dragging")
    document.body.classList.add("tier-dragging")

    this.moveGhost(event.clientX, event.clientY)
    this.updateDropTarget(event.clientX, event.clientY)
  }

  moveGhost(x, y) {
    if (!this.ghost) return
    this.ghost.style.left = `${x - this.dragOffsetX}px`
    this.ghost.style.top = `${y - this.dragOffsetY}px`
  }

  // ===== Определение зоны и позиции сброса =====

  updateDropTarget(x, y) {
    const element = document.elementFromPoint(x, y)
    const zone = element ? element.closest('[data-tier-list-target="zone"]') : null

    this.setActiveZone(zone)
    if (!zone || !this.dragCard) return

    const card = this.dragCard
    const siblings = Array.from(zone.querySelectorAll('[data-tier-list-target="card"]')).filter((item) => item !== card)

    if (siblings.length === 0) {
      if (card.parentNode !== zone) zone.appendChild(card)
      return
    }

    // Ближайшая по центру карточка; вставляем до или после неё в зависимости от стороны.
    let closest = null
    let closestRect = null
    let minDistance = Infinity

    for (const sibling of siblings) {
      const rect = sibling.getBoundingClientRect()
      const dx = x - (rect.left + rect.width / 2)
      const dy = y - (rect.top + rect.height / 2)
      const distance = dx * dx + dy * dy
      if (distance < minDistance) {
        minDistance = distance
        closest = sibling
        closestRect = rect
      }
    }

    const insertAfter = x > closestRect.left + closestRect.width / 2

    if (insertAfter) {
      if (card.previousElementSibling === closest) return
      closest.after(card)
    } else {
      if (card.nextElementSibling === closest) return
      closest.before(card)
    }
  }

  setActiveZone(zone) {
    if (this.activeZone === zone) return
    if (this.activeZone) this.activeZone.classList.remove("tier-zone--active")
    this.activeZone = zone
    if (zone) zone.classList.add("tier-zone--active")
  }

  finishDrag() {
    if (this.dragCard) this.dragCard.classList.remove("tier-card--dragging")
    this.removeGhost()
    this.setActiveZone(null)
    document.body.classList.remove("tier-dragging")
    this.dragCard = null
    this.ghost = null
    this.scheduleSave()
  }

  removeGhost() {
    if (this.ghost && this.ghost.parentNode) {
      this.ghost.parentNode.removeChild(this.ghost)
    }
    this.ghost = null
  }

  // ===== Сохранение =====

  serialize() {
    const layout = {}
    this.zoneTargets.forEach((zone) => {
      const rank = zone.dataset.rank
      if (!rank) return
      layout[rank] = Array.from(zone.querySelectorAll('[data-tier-list-target="card"]'))
        .map((card) => parseInt(card.dataset.elementId, 10))
        .filter((id) => !Number.isNaN(id))
    })
    return layout
  }

  scheduleSave() {
    this.dirty = true
    if (this.saving) return
    this.performSave()
  }

  retry(event) {
    if (event) event.preventDefault()
    this.performSave()
  }

  async performSave() {
    this.saving = true
    this.dirty = false
    this.setStatus("saving")

    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({ layout: this.serialize() })
      })

      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      // Успех показываем только после подтверждения сервера.
      this.setStatus("saved")
    } catch (error) {
      this.setStatus("error")
    } finally {
      this.saving = false
      if (this.dirty) this.performSave()
    }
  }

  setStatus(state) {
    if (!this.hasStatusTarget) return
    clearTimeout(this.statusTimer)

    const status = this.statusTarget
    const retry = this.hasRetryTarget ? this.retryTarget : null
    if (retry) retry.hidden = true

    if (state === "saving") {
      status.className = "tier-save-status is-saving"
      status.textContent = "Сохранение…"
    } else if (state === "saved") {
      status.className = "tier-save-status is-saved"
      status.textContent = "Сохранено"
      this.statusTimer = setTimeout(() => {
        status.textContent = ""
        status.className = "tier-save-status"
      }, 2000)
    } else {
      status.className = "tier-save-status is-error"
      status.textContent = "Не удалось сохранить"
      if (retry) retry.hidden = false
    }
  }

  // ===== Удаление нераспределённого элемента =====

  // Открывает диалог подтверждения удаления.
  deleteElement(event) {
    event.stopPropagation()
    event.preventDefault()

    const button = event.currentTarget
    this.pendingDeleteId = button.dataset.elementId
    this.showDeleteConfirm()
  }

  cancelDelete(event) {
    if (event) event.preventDefault()
    this.hideDeleteConfirm()
    this.pendingDeleteId = null
  }

  // Подтверждённое удаление: отправляет DELETE на сервер и убирает карточку при успехе.
  async confirmDelete(event) {
    if (event) event.preventDefault()
    if (!this.pendingDeleteId) return

    this.hideDeleteConfirm()
    const elementId = this.pendingDeleteId
    this.pendingDeleteId = null

    try {
      const response = await fetch(
        `/tier_lists/${this.tierListId()}/elements/${elementId}`,
        {
          method: "DELETE",
          headers: {
            "Accept": "application/json",
            "X-CSRF-Token": this.csrfToken
          }
        }
      )

      if (!response.ok) {
        const body = await response.json().catch(() => ({}))
        alert(body.error || "Не удалось удалить элемент")
        return
      }

      const card = document.querySelector(`[data-tier-list-target="card"][data-element-id="${elementId}"]`)
      if (card) card.remove()

      this.updateUnrankedCount()
      this.showEmptyStateIfNeeded()
    } catch (error) {
      alert("Не удалось удалить элемент")
    }
  }

  // Закрывает модальное окно создания элемента после успешного сохранения.
  // Вызывается по turbo:submit-end из формы создания элемента.
  closeElementModal(event) {
    const overlay = this.element.querySelector("#tier-element-modal")
    if (!overlay) return
    // Если сервер вернул ошибки валидации, модалка остаётся открытой с ошибками.
    if (overlay.querySelector(".error-messages")) return
    overlay.style.display = "none"
    document.body.style.overflow = ""
    // Сбрасываем форму и счётчик символов, чтобы при следующем открытии поля были пустыми.
    const form = overlay.querySelector("form")
    if (form) form.reset()
    const counter = overlay.querySelector('[data-modal-target="charCounter"]')
    if (counter) counter.textContent = "0"
    this.showEmptyStateIfNeeded()
  }

  // ===== Модалка импорта из каталога =====

  importModalOpen(event) {
    if (event) event.preventDefault()
    this.importOverlayTarget.style.display = "flex"
    document.body.style.overflow = "hidden"
  }

  importModalClose(event) {
    if (event) event.preventDefault()
    this.importOverlayTarget.style.display = "none"
    document.body.style.overflow = ""
    const form = this.importOverlayTarget.querySelector("form")
    if (form) form.reset()
  }

  importModalCloseOnOverlay(event) {
    if (event.target === this.importOverlayTarget) {
      this.importModalClose()
    }
  }

  // Вызывается по turbo:submit-end из формы импорта.
  importDone(event) {
    const response = event.detail && event.detail.fetchResponse
    // При ошибке валидации/сервера модалка остаётся открытой — пользователь видит сообщение.
    if (response && !response.ok) {
      response.text().then((text) => {
        alert(text || "Не удалось импортировать элементы")
      }).catch(() => alert("Не удалось импортировать элементы"))
      return
    }
    this.importModalClose()
    this.showEmptyStateIfNeeded()
  }

  showDeleteConfirm() {
    if (!this.deleteConfirmTarget) return
    this.deleteConfirmTarget.style.display = "flex"
  }

  hideDeleteConfirm() {
    if (!this.deleteConfirmTarget) return
    this.deleteConfirmTarget.style.display = "none"
  }

  // ID открытого тирлиста берём из URL текущей страницы.
  tierListId() {
    const match = window.location.pathname.match(/\/tier_lists\/(\d+)/)
    return match ? match[1] : ""
  }

  updateUnrankedCount() {
    const countEl = document.getElementById("tier-unranked-count")
    if (!countEl) return
    const zone = document.getElementById("tier-unranked-zone")
    if (!zone) return
    const remaining = zone.querySelectorAll('[data-tier-list-target="card"]').length
    countEl.textContent = remaining.toString()
  }

  showEmptyStateIfNeeded() {
    const zone = document.getElementById("tier-unranked-zone")
    const empty = document.getElementById("tier-empty-state")
    if (!zone || !empty) return
    const hasCards = zone.querySelectorAll('[data-tier-list-target="card"]').length > 0
    empty.style.display = hasCards ? "none" : "block"
  }

  get csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ""
  }
}
