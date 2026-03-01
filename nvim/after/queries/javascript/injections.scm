; extends

; Styled JSX: <style jsx>{`...css...`}</style>
(jsx_element
  (jsx_opening_element
    (identifier) @_name
    (#eq? @_name "style")
    (jsx_attribute
      (property_identifier) @_attr
      (#eq? @_attr "jsx")))
  (jsx_expression
    (template_string
      (string_fragment) @injection.content
      (#set! injection.language "css"))))
