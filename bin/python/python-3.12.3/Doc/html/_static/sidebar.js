/*
 * sidebar.js
 * ~~~~~~~~~~
 *
 * This file is functionally identical to "sidebar.js" in Sphinx 5.0.
 * When support for Sphinx 4 and earlier is dropped from the theme,
 * this file can be removed.
 *
 * This script makes the Sphinx sidebar collapsible.
 *
 * .sphinxsidebar contains .sphinxsidebarwrapper.  This script adds
 * in .sphinxsidebar, after .sphinxsidebarwrapper, the #sidebarbutton
 * used to collapse and expand the sidebar.
 *
 * When the sidebar is collapsed the .sphinxsidebarwrapper is hidden
 * and the width of the sidebar and the margin-left of the document
 * are decreased. When the sidebar is expanded the opposite happens.
 * This script saves a per-browser/per-session cookie used to
 * remember the position of the sidebar among the pages.
 * Once the browser is closed the cookie is deleted and the position
 * reset to the default (expanded).
 *
 * :copyright: Copyright 2007-2022 by the Sphinx team, see AUTHORS.
 * :license: BSD, see LICENSE for details.
 *
 */

const initialiseSidebar = () => {
  // global elements used by the functions.
  const bodyWrapper = document.getElementsByClassName("bodywrapper")[0]
  const sidebar = document.getElementsByClassName("sphinxsidebar")[0]
  const sidebarWrapper = document.getElementsByClassName("sphinxsidebarwrapper")[0]

  // exit early if the document has no sidebar for some reason
  if (typeof sidebar === "undefined") {
    return
  }



  const sidebarButton = document.getElementById("sidebarbutton")
  const sidebarArrow = sidebarButton.querySelector('span')


  const collapse_sidebar = () => {
    bodyWrapper.style.marginLeft = ".8em"
    sidebar.style.width = ".8em"
    sidebarWrapper.style.display = "none"
    sidebarArrow.innerText = "»"
    sidebarButton.title = _("Expand sidebar")
    window.localStorage.setItem("sidebar", "collapsed")
  }

  const expand_sidebar = () => {
    bodyWrapper.style.marginLeft = ""
    sidebar.style.removeProperty("width")
    sidebarWrapper.style.display = ""
    sidebarArrow.innerText = "«"
    sidebarButton.title = _("Collapse sidebar")
    window.localStorage.setItem("sidebar", "expanded")
  }

  sidebarButton.addEventListener("click", () => {
    (sidebarWrapper.style.display === "none") ? expand_sidebar() : collapse_sidebar()
  })

  const sidebar_state = window.localStorage.getItem("sidebar")
  if (sidebar_state === "collapsed") {
    collapse_sidebar()
  }
  else if (sidebar_state === "expanded") {
    expand_sidebar()
  }
}

if (document.readyState !== "loading") {
  initialiseSidebar()
}
else {
  document.addEventListener("DOMContentLoaded", initialiseSidebar)
}