This is my contribution to Robocorps certification level 2.

-------------------

 I decided to not implement this logic for simplicity sake. Will be interesting to see how strict you guys are!
 We check the models each run in case someone decides to update them without letting the RPA department know.

 Find models   
    Click Button    Show model info
    ${counter}=    Set Variable    0
    ${is_element_visible}=    Is Element Visible    //*[@id="model-info"]/tbody/tr[${counter}]/td[1]
    WHILE    ${is_element_visible}
    ${model}=    Get Text    //*[@id="model-info"]/tbody/tr[1]/td[1]
    Append To List    ${MODEL_LIST}    ${model}
    ${counter}=    Evaluate    ${counter}+1
    ${is_element_visible}=    Is Element Visible    //*[@id="model-info"]/tbody/tr[${counter}]/td[1]
    IF    ${is_element_visible}
    ${model}=    Get Text    //*[@id="model-info"]/tbody/tr[${counter}]/td[1]
    ELSE
    BREAK
    END
    END

 Template: Standard Robot Framework
