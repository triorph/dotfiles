; Inject python highlighting for signalflow programs
(attribute
  (identifier) @_name (#eq? @_name "program_text")
  (expression 
	(template_expr 
	  (heredoc_template 
		(template_literal) @python))))
