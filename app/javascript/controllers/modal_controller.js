import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "dialog", "previewLetter", "previewTitle", "previewDesc", "charCounter", "previewStars", "previewRating", "ratingStars", "ratingValue"]

  connect() {
    document.addEventListener("keydown", this.handleKeydown.bind(this))
    this.setupPreviewListeners()
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown.bind(this))
  }

  setupPreviewListeners() {
    // Счётчик символов для названия
    const titleInput = this.dialogTarget.querySelector("input[name='catalog[name]'], input[name='element[title]'], input[name='tier_list[title]']")
    if (titleInput) {
      titleInput.addEventListener("input", () => {
        this.updateCharCounter(titleInput)
        this.updatePreview()
      })
    }

    // Описание
    const descInput = this.dialogTarget.querySelector("textarea[name='catalog[description]'], textarea[name='element[description]'], textarea[name='tier_list[description]']")
    if (descInput) {
      descInput.addEventListener("input", () => this.updatePreview())
    }

    // Цвет (для каталогов)
    const colorInput = this.dialogTarget.querySelector("input[type='color']")
    if (colorInput) {
      colorInput.addEventListener("input", () => this.updatePreview())
    }

    // Звёзды рейтинга (для элементов)
    if (this.hasRatingStarsTarget) {
      this.setupRatingStars()
    }
  }

  updateCharCounter(input) {
    if (this.hasCharCounterTarget) {
      this.charCounterTarget.textContent = input.value.length
    }
  }

  setupRatingStars() {
    const stars = this.ratingStarsTarget.querySelectorAll(".rating-star")
    let currentRating = 0

    stars.forEach((star, index) => {
      // Подсветка при наведении
      star.addEventListener("mouseenter", () => {
        this.highlightStars(index + 1)
      })

      // Выбор рейтинга
      star.addEventListener("click", () => {
        currentRating = index + 1
        this.highlightStars(currentRating)
        this.updateRatingDisplay(currentRating)

        // Скрытое поле
        const hiddenField = this.dialogTarget.querySelector("input[name='element[rating]']")
        if (hiddenField) {
          hiddenField.value = currentRating
        }
      })
    })

    // Возврат к выбранному рейтингу при уходе курсора
    this.ratingStarsTarget.addEventListener("mouseleave", () => {
      this.highlightStars(currentRating)
    })
  }

  highlightStars(count) {
    const stars = this.ratingStarsTarget.querySelectorAll(".rating-star")
    stars.forEach((star, index) => {
      if (index < count) {
        star.classList.add("star-active")
      } else {
        star.classList.remove("star-active")
      }
    })
  }

  updateRatingDisplay(rating) {
    if (this.hasRatingValueTarget) {
      this.ratingValueTarget.textContent = rating
    }
  }

  open(event) {
    event.preventDefault()
    this.overlayTarget.style.display = "flex"
    document.body.style.overflow = "hidden"

    // Сбрасываем форму
    const form = this.dialogTarget.querySelector("form")
    if (form) {
      form.reset()
    }
    if (this.hasCharCounterTarget) {
      this.charCounterTarget.textContent = "0"
    }
    if (this.hasRatingValueTarget) {
      this.ratingValueTarget.textContent = "0"
      this.highlightStars(0)
    }
    this.updatePreview()

    // Фокус на первое поле
    const firstInput = this.dialogTarget.querySelector("input[type='text']")
    if (firstInput) {
      setTimeout(() => firstInput.focus(), 100)
    }
  }

  close() {
    this.overlayTarget.style.display = "none"
    document.body.style.overflow = ""

    // Сбрасываем форму
    const form = this.dialogTarget.querySelector("form")
    if (form) {
      form.reset()
    }
    this.updatePreview()

    // Возвращаем фокус на кнопку создания
    const addButton = this.element.querySelector(".btn-primary")
    if (addButton) {
      addButton.focus()
    }
  }

  closeOnOverlay(event) {
    if (event.target === this.overlayTarget) {
      this.close()
    }
  }

  setColor(event) {
    const color = event.currentTarget.dataset.color
    const colorInput = this.dialogTarget.querySelector("input[type='color']")
    if (colorInput) {
      colorInput.value = color
    }
    this.updatePreview()
  }

  setRating(event) {
    const rating = parseInt(event.currentTarget.dataset.rating)
    this.highlightStars(rating)
    this.updateRatingDisplay(rating)

    const hiddenField = this.dialogTarget.querySelector("input[name='element[rating]']")
    if (hiddenField) {
      hiddenField.value = rating
    }
  }

  updatePreview() {
    const nameInput = this.dialogTarget.querySelector("input[name='catalog[name]'], input[name='element[title]']")
    const descInput = this.dialogTarget.querySelector("textarea[name='catalog[description]'], textarea[name='element[description]']")
    const colorInput = this.dialogTarget.querySelector("input[type='color']")

    if (nameInput && this.hasPreviewLetterTarget) {
      const name = nameInput.value.trim()
      this.previewLetterTarget.textContent = name ? name[0].toUpperCase() : "?"
      this.previewTitleTarget.textContent = name || "Название элемента"
    }

    if (descInput && this.hasPreviewDescTarget) {
      const desc = descInput.value.trim()
      this.previewDescTarget.textContent = desc || "Описание элемента"
    }

    if (colorInput) {
      const previewCard = this.dialogTarget.querySelector(".catalog-preview")
      if (previewCard) {
        previewCard.style.borderColor = colorInput.value
      }
    }

    // Обновляем звёзды рейтинга в предпросмотре
    if (this.hasPreviewStarsTarget) {
      const hiddenField = this.dialogTarget.querySelector("input[name='element[rating]']")
      const rating = hiddenField ? parseInt(hiddenField.value) || 0 : 0

      let starsHtml = ""
      for (let i = 1; i <= 10; i++) {
        starsHtml += `<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="${i <= rating ? 'star-filled' : 'star-empty'}"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon></svg>`
      }
      this.previewStarsTarget.innerHTML = starsHtml

      if (this.hasPreviewRatingTarget) {
        this.previewRatingTarget.textContent = `${rating}/10`
      }
    }
  }

  // Обработка Escape
  handleKeydown(event) {
    if (event.key === "Escape" && this.overlayTarget.style.display !== "none") {
      this.close()
    }
  }

  // Блокировка повторной отправки формы
  submitStart(event) {
    const submitButton = event.target.querySelector("input[type='submit']")
    if (submitButton) {
      submitButton.disabled = true
      submitButton.value = "Создание..."
    }
  }

  submitEnd(event) {
    const submitButton = event.target.querySelector("input[type='submit']")
    if (submitButton) {
      submitButton.disabled = false
      // Восстанавливаем исходный текст кнопки
      const form = event.target
      if (form.querySelector("input[name='tier_list[title]']")) {
        submitButton.value = "Создать тирлист"
      } else if (form.querySelector("input[name='catalog[name]']")) {
        submitButton.value = "Создать каталог"
      } else {
        submitButton.value = "Создать элемент"
      }
    }
  }
}
