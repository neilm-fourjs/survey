
-- A simple dynamic survey example

-- Data structure:
--  survey_name
--    category
--      questions
--        answers

IMPORT util
IMPORT os

TYPE t_survey RECORD
		name STRING,
		categories DYNAMIC ARRAY OF RECORD
			name STRING,
			questions DYNAMIC ARRAY OF RECORD
				question_type STRING,
				question_text STRING,
				answer_choice STRING,
				answers DYNAMIC ARRAY OF RECORD
					code CHAR(1),
					answer_text STRING
				END RECORD -- answers
			END RECORD -- quests
		END RECORD -- cats
	END RECORD -- survey

DEFINE m_survey t_survey
DEFINE m_questions SMALLINT
MAIN
	DEFINE l_json_survey, l_file, l_answers STRING
	DEFINE c,q SMALLINT

	LET l_file = ARG_VAL(1)
	IF l_file.getLength() < 2 THEN LET l_file = "genero" END IF
	LET l_file = "../data/"||l_file||".json"
	IF NOT os.path.exists( l_file ) THEN
		CALL fgl_winMessage("Error","Survey file not found!\n"||l_file,"exclamation")
		EXIT PROGRAM
	END IF
	LET l_json_survey = read_json(l_file)
	CALL util.JSON.parse( l_json_survey, m_survey )

	LET m_questions = 0
	FOR c = 1 TO m_survey.categories.getLength()
		FOR q = 1 TO m_survey.categories[c].questions.getLength()
			LET m_questions = m_questions + 1
		END FOR
	END FOR
	
	DISPLAY "Questions:", m_questions, " Categories:", m_survey.categories.getLength()

	CALL render_screen()

	{MENU -- check screen
		ON ACTION close EXIT MENU
		ON ACTION continue EXIT MENU
	END MENU}

	LET int_flag = FALSE
	CALL dynamic_input()
	IF int_flag THEN EXIT PROGRAM END IF

	FOR c = 1 TO m_survey.categories.getLength()
		FOR q = 1 TO m_survey.categories[c].questions.getLength()
			LET l_answers = l_answers.append(m_survey.categories[c].questions[q].question_text||" = "||m_survey.categories[c].questions[q].answer_choice||"\n")
		END FOR
	END FOR
	DISPLAY BY NAME l_answers

	MENU
		ON ACTION cancel EXIT MENU
		ON ACTION close EXIT MENU
	END MENU

END MAIN
--------------------------------------------------------------------------------
FUNCTION read_json(l_file)
	DEFINE l_file, l_data STRING
	DEFINE c base.Channel
	LET c = base.Channel.create()
	CALL c.openFile(l_file,"r")
	WHILE NOT c.isEof()
		LET l_data = l_data.append( c.readLine() )
	END WHILE
	CALL c.close()
	RETURN l_data
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION render_screen()
	DEFINE l_w ui.Window
	DEFINE l_f ui.Form
	DEFINE l_n, l_g om.DomNode
	DEFINE x,c,q SMALLINT
	OPEN FORM f FROM "survey"
	DISPLAY FORM f
	CALL ui.Interface.setText("A Survey Demo")
	LET l_w = ui.Window.getCurrent()
	CALL l_w.setText("Survey - "||m_survey.name)
	LET l_f = l_w.getForm()
	LET l_n = l_f.findNode("Grid","questions")
	LET q = 0
	FOR c = 1 TO m_survey.categories.getLength()
		LET l_g = l_n.createChild("Group")
		CALL l_g.setAttribute("text",m_survey.categories[c].name)
		CALL l_g.setAttribute("posY",c)
		FOR x = 1 TO m_survey.categories[c].questions.getLength()
			LET q = q + 1
			CALL add_question( l_g, x, c, q )
		END FOR
	END FOR
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION add_question(l_n, x, c,q)
	DEFINE l_n,l_n1 om.DomNode
	DEFINE c, x, y, q SMALLINT
	DEFINE l_style STRING

	LET l_style = "style1"
	IF x MOD 2 THEN
		LET l_style = "style2"
	END IF

	LET l_n1 = l_n.createChild("Label")
	CALL l_n1.setAttribute("name","quest"||x)
	IF x > m_questions THEN
		CALL l_n1.setAttribute("hidden",TRUE)
	ELSE
		CALL l_n1.setAttribute("text",m_survey.categories[c].questions[x].question_text||"     ")
	END IF
	CALL l_n1.setAttribute("posX",0)
	CALL l_n1.setAttribute("posY",x)
	CALL l_n1.setAttribute("gridWidth",50)
	CALL l_n1.setAttribute("style",l_style)

	LET l_n = l_n.createChild("FormField")
	CALL l_n.setAttribute("name","formonly.question"||q)
	CALL l_n.setAttribute("colName","question"||q)
	CALL l_n.setAttribute("screenRecord","formonly")

	LET l_n = l_n.createChild("RadioGroup")
	IF x > m_questions THEN
		CALL l_n.setAttribute("hidden",TRUE)
	END IF

	CALL l_n.setAttribute("orientation","horizontal")
	CALL l_n.setAttribute("posX",50)
	CALL l_n.setAttribute("posY",x)
	CALL l_n.setAttribute("gridWidth",100)
	CALL l_n.setAttribute("width",100)
	CALL l_n.setAttribute("style",l_style)

	FOR y = 1 TO m_survey.categories[c].questions[x].answers.getLength()
		LET l_n1 = l_n.createChild("Item") 
		CALL l_n1.setAttribute("text",m_survey.categories[c].questions[x].answers[y].answer_text)
		CALL l_n1.setAttribute("name",m_survey.categories[c].questions[x].answers[y].code)
	END FOR
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION dynamic_input()
	DEFINE l_flds DYNAMIC ARRAY OF RECORD
			name STRING,
			type STRING
		END RECORD
	DEFINE d ui.Dialog
	DEFINE c, x, q SMALLINT
	DISPLAY "Dynamic Input"
	FOR x = 1 TO m_questions -- create fields for input
		LET l_flds[x].name = "question"||x
		LET l_flds[x].type = "CHAR(1)"
	END FOR

	LET d = ui.Dialog.createInputByName(l_flds)
	CALL d.addTrigger("ON ACTION accept")
	CALL d.addTrigger("ON ACTION cancel")

	WHILE TRUE -- process the dialog
		CASE d.nextEvent()
			WHEN "ON ACTION accept"
				CALL d.accept()
				EXIT WHILE
			WHEN "ON ACTION cancel"
				CALL d.cancel()
				EXIT WHILE
		END CASE
	END WHILE
	IF int_flag THEN RETURN END IF
	LET q = 0
	FOR c = 1 TO m_survey.categories.getLength()
		FOR x = 1 TO m_survey.categories[c].questions.getLength() -- get the answers from the dialog
			LET q = q + 1
			LET m_survey.categories[c].questions[x].answer_choice = d.getFieldValue("formonly.question"||q)
		END FOR
	END FOR
END FUNCTION