#set page(
  numbering: "1",
  header: context {
    // Get current heading
    let elems = query(selector(heading.where(level: 1)).before(here()))
    let current-heading = if elems.len() > 0 {
      elems.last().body
    } else {
      []
    }
    
    let page-num = here().page()
    set text(size: 10pt)
    
    if calc.odd(page-num) {
      // Odd pages: heading on right
      align(right)[#emph(current-heading)]
    } else {
      // Even pages: heading on left
      align(left)[#emph(current-heading)]
    }
    
    v(0.3em)
    line(length: 100%, stroke: 0.5pt)
  },
  footer: context {
    let page-num = here().page()
    if calc.odd(page-num) {
      align(right)[#counter(page).display()]  // Odd: right
    } else {
      align(left)[#counter(page).display()]   // Even: left
    }
  }
)

#counter(page).update(1)
