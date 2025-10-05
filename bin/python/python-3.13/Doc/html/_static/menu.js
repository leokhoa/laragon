document.addEventListener("DOMContentLoaded", function () {

    // Make tables responsive by wrapping them in a div and making them scrollable
    const tables = document.querySelectorAll("table.docutils")
    tables.forEach(function(table){
        table.outerHTML = '<div class="responsive-table__container">' + table.outerHTML + "</div>"
    })

    const togglerInput = document.querySelector(".toggler__input")
    const togglerLabel = document.querySelector(".toggler__label")
    const sideMenu = document.querySelector(".menu-wrapper")
    const menuItems = document.querySelectorAll(".menu")
    const doc = document.querySelector(".document")
    const body = document.querySelector("body")

    function closeMenu() {
        togglerInput.checked = false
        sideMenu.setAttribute("aria-expanded", "false")
        sideMenu.setAttribute("aria-hidden", "true")
        togglerLabel.setAttribute("aria-pressed", "false")
        body.style.overflow = "visible"
    }
    function openMenu() {
        togglerInput.checked = true
        sideMenu.setAttribute("aria-expanded", "true")
        sideMenu.setAttribute("aria-hidden", "false")
        togglerLabel.setAttribute("aria-pressed", "true")
        body.style.overflow = "hidden"
    }

    // Close menu when link on the sideMenu is clicked
    sideMenu.addEventListener("click", function (event) {
        let target = event.target
        if (target.tagName.toLowerCase() !== "a") {
            return
        }
        closeMenu()
    })
    // Add accessibility data when sideMenu is opened/closed
    togglerInput.addEventListener("change", function (_event) {
        togglerInput.checked ? openMenu() : closeMenu()
    })
    // Make sideMenu links tabbable only when visible
    for(let menuItem of menuItems) {
        if(togglerInput.checked) {
          menuItem.setAttribute("tabindex", "0")
        } else {
          menuItem.setAttribute("tabindex", "-1")
        }
    }
    // Close sideMenu when document body is clicked
    doc.addEventListener("click", function () {
        if (togglerInput.checked) {
            closeMenu()
        }
    })
})
