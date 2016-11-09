
-- program to create the surveys

OPTIONS SHORT CIRCUIT

IMPORT util

TYPE t_survey RECORD
		name STRING,
		categories DYNAMIC ARRAY OF RECORD
			name STRING,
			questions DYNAMIC ARRAY OF RECORD
				question_type STRING,
				question_text STRING,
				answers DYNAMIC ARRAY OF RECORD
					code CHAR(1),
					answer_text STRING
				END RECORD -- answers
			END RECORD -- quests
		END RECORD -- cats
	END RECORD -- survey

DEFINE m_survey t_survey

MAIN

	OPEN FORM f FROM "survey_gen"
	DISPLAY FORM f
	CALL ui.Interface.setText("A Survey Demo")
	MENU
		ON ACTION new CALL new_survey()
		ON ACTION close EXIT MENU
		ON ACTION quit EXIT MENU
	END MENU
	
END MAIN
--------------------------------------------------------------------------------
FUNCTION new_survey()
	DEFINE l_survey_name,l_cat, l_quest_type, l_quest STRING
	DEFINE l_arr DYNAMIC ARRAY OF RECORD
			category STRING,
			question_type STRING,
			question STRING
		END RECORD
	DEFINE l_qans DYNAMIC ARRAY OF RECORD
			l_ans DYNAMIC ARRAY OF RECORD
				answer_code CHAR(1),
				answer STRING
			END RECORD
		END RECORD
	DEFINE d ui.Dialog
	DEFINE q,y,x,a SMALLINT
	DEFINE l_ans STRING

	LET l_quest_type = "S"
	DIALOG ATTRIBUTE(UNBUFFERED)
		INPUT BY NAME l_survey_name
		END INPUT
		INPUT BY NAME l_cat, l_quest_type, l_quest ATTRIBUTES(WITHOUT DEFAULTS )
			AFTER INPUT
				IF l_quest IS NOT NULL THEN
					CALL l_arr.appendElement()
					LET q = l_arr.getLength()
					LET l_arr[ q ].category = l_cat;
					LET l_arr[ q ].question = l_quest;
					LET l_arr[ q ].question_type = l_quest_type;
					LET int_flag = FALSE
					DISPLAY ARRAY l_arr TO scr_arr_1.*
						BEFORE DISPLAY EXIT DISPLAY
					END DISPLAY
					INPUT ARRAY l_qans[ q ].l_ans FROM scr_arr_2.* ATTRIBUTES(UNBUFFERED, WITHOUT DEFAULTS )
						BEFORE FIELD answer
							LET l_qans[ q ].l_ans[ arr_curr() ].answer_code = ASCII( 96 + arr_curr() )
					END INPUT
					IF int_flag THEN
						CALL l_arr.deleteElement( q )
						CALL l_qans.deleteElement( q )
						LET int_flag = FALSE
					ELSE
						MESSAGE "Added."
						CALL DIALOG.setCurrentRow( "scr_arr_1", q )
					END IF
					LET l_quest = NULL
					NEXT FIELD l_quest
				END IF
		END INPUT
		DISPLAY ARRAY l_arr TO scr_arr_1.*
			BEFORE ROW
				LET q = arr_curr()
				LET x = scr_line()
				DISPLAY ARRAY l_qans[ q ].l_ans TO scr_arr_2.*
					BEFORE DISPLAY EXIT DISPLAY
				END DISPLAY
			ON ACTION edit_question
				INPUT l_arr[ q ].question FROM scr_arr_1[ x ].question ATTRIBUTES( WITHOUT DEFAULTS )
					AFTER FIELD question
--
				END INPUT
			ON ACTION edit_answers
				INPUT ARRAY l_qans[ l_arr.getLength() ].l_ans WITHOUT DEFAULTS FROM scr_arr_2.*
					BEFORE FIELD answer
						LET l_qans[ q ].l_ans[ arr_curr() ].answer_code = ASCII( 96 + arr_curr() )
				END INPUT
				IF int_flag THEN
					CALL l_arr.deleteElement( l_arr.getLength() )
					CALL l_qans.deleteElement( l_arr.getLength() )
					LET int_flag = FALSE
				ELSE
					MESSAGE "Added."
					CALL DIALOG.setCurrentRow( "scr_arr_1", l_arr.getLength() )
				END IF
			ON DELETE
				MESSAGE "Deleted."
		END DISPLAY
		ON ACTION close EXIT DIALOG
		ON ACTION exit_save
			LET l_ans = fgl_winQuestion("Confirm","Save this survey ?","Yes","Yes|No|Cancel","question",1)
			IF l_ans = "Cancel" THEN
				NEXT FIELD question
			END IF
			IF l_ans = "Yes" THEN
				LET m_survey.name = l_survey_name
				LET x = 1
				LET y = 0
				LET m_survey.categories[x].name = l_arr[1].category
				FOR q = 1 TO l_arr.getLength()
					IF l_arr[q].category IS NOT NULL 
					AND l_arr[q].question IS NOT NULL
					AND l_qans[q].l_ans.getLength() > 0 THEN
						IF m_survey.categories[x].name != l_arr[q].category THEN
							LET x = x + 1
							LET y = 0
						END IF
						LET y = y + 1
						LET m_survey.categories[x].name = l_arr[q].category
						LET m_survey.categories[x].questions[y].question_type = l_arr[q].question_type
						LET m_survey.categories[x].questions[y].question_text = l_arr[q].question
						FOR a = 1 TO l_qans[q].l_ans.getLength()
							IF l_qans[q].l_ans[a].answer IS NOT NULL THEN
								CALL m_survey.categories[x].questions[y].answers.appendElement()
								LET m_survey.categories[x].questions[y].answers[ m_survey.categories[x].questions[y].answers.getLength() ].code = l_qans[q].l_ans[a].answer_code
								LET m_survey.categories[x].questions[y].answers[ m_survey.categories[x].questions[y].answers.getLength() ].answer_text = l_qans[q].l_ans[a].answer
							END IF
						END FOR
					END IF
				END FOR
				CALL save()
			END IF
			EXIT DIALOG
	END DIALOG

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION save()
	DEFINE l_json util.JSONObject
	DEFINE l_str STRING
	DEFINE c base.Channel
	DEFINE x om.DomNode

-- debug
	LET x = base.TypeInfo.create( m_survey )
	CALL x.writeXml( "../data/"||m_survey.name||".xml")

-- convert to json
	LET l_json = util.jsonObject.fromFGL( m_survey )
	LET l_str = l_json.toString()

	DISPLAY "JSON:",l_str

	LET c = base.Channel.create()
	CALL c.openFile( "../data/"||m_survey.name||".json","w" )
	CALL c.writeLine( l_str )
	CALL c.close()
END FUNCTION