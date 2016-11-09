
-- A simple dynamic survey example

-- Data structure:
--  survey_name
--    category
--      questions
--        answers

IMPORT util

CONSTANT C_MAX_QUESTIONS = 10

TYPE t_survey RECORD
		question STRING,
		answers DYNAMIC ARRAY OF STRING,
		answer STRING
	END RECORD

DEFINE m_survey DYNAMIC ARRAY OF t_survey
DEFINE m_questions SMALLINT

MAIN
	DEFINE l_json_survey, l_answers STRING
	DEFINE x SMALLINT

	LET l_json_survey = read_json("../data/survey.json")
	CALL util.JSON.parse( l_json_survey, m_survey )

	LET m_questions = m_survey.getLength()

	CALL render_screen()

	LET int_flag = FALSE
	CALL dynamic_input()
	IF int_flag THEN EXIT PROGRAM END IF

	FOR x = 1 TO m_questions
		LET l_answers = l_answers.append(x||". "||m_survey[x].question||
		" = "||NVL(m_survey[x].answer,"NULL")||
		IIF( m_survey[x].answer IS NOT NULL," ("||m_survey[x].answers[ m_survey[x].answer ]||")"," ")||"\n")
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
	DEFINE l_n om.DomNode
	DEFINE x SMALLINT
	OPEN FORM f FROM "survey"
	DISPLAY FORM f
	LET l_w = ui.Window.getCurrent()
	LET l_f = l_w.getForm()
	LET l_n = l_f.findNode("Grid","questions")
	FOR x = 1 TO C_MAX_QUESTIONS
		CALL add_question( l_n, x )
	END FOR
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION add_question(l_n, x)
	DEFINE l_n,l_n1 om.DomNode
	DEFINE x,y SMALLINT
	DEFINE l_style  STRING

	LET l_style = "style1"
	IF x MOD 2 THEN
		LET l_style = "style2"
	END IF

	LET l_n1 = l_n.createChild("Label")
	CALL l_n1.setAttribute("name","quest"||x)
	IF x > m_survey.getLength() THEN
		CALL l_n1.setAttribute("hidden",TRUE)
	ELSE
		CALL l_n1.setAttribute("text",m_survey[x].question)
	END IF
	CALL l_n1.setAttribute("posX",0)
	CALL l_n1.setAttribute("posY",x)
	CALL l_n1.setAttribute("gridWidth",50)
	CALL l_n1.setAttribute("style",l_style)

	LET l_n = l_n.createChild("FormField")
	CALL l_n.setAttribute("name","formonly.question"||x)
	CALL l_n.setAttribute("colName","question"||x)
	CALL l_n.setAttribute("screenRecord","formonly")

	LET l_n = l_n.createChild("RadioGroup")
	IF x > m_survey.getLength() THEN
		CALL l_n.setAttribute("hidden",TRUE)
	END IF
	CALL l_n.setAttribute("orientation","horizontal")
	CALL l_n.setAttribute("posX",50)
	CALL l_n.setAttribute("posY",x)
	CALL l_n.setAttribute("gridWidth",100)
	CALL l_n.setAttribute("width",100)
	CALL l_n.setAttribute("style",l_style)

	FOR y = 1 TO m_survey[x].answers.getLength()
		LET l_n1 = l_n.createChild("Item") 
		CALL l_n1.setAttribute("text",m_survey[x].answers[y])
		CALL l_n1.setAttribute("name",y)
	END FOR
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION dynamic_input()
	DEFINE l_flds DYNAMIC ARRAY OF RECORD
			name STRING,
			type STRING
		END RECORD
	DEFINE d ui.Dialog
	DEFINE x SMALLINT
	DISPLAY "Dynamic Input"
	FOR x = 1 TO m_questions -- create fields for input
		LET l_flds[x].name = "question"||x
		LET l_flds[x].type = "SMALLINT"
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

	FOR x = 1 TO m_questions -- get the answers from the dialog
		LET m_survey[x].answer = d.getFieldValue("formonly.question"||x)
	END FOR

END FUNCTION