function chooseVariable(hObject,eventdata, type)
handles = guidata(hObject);
    if (strcmp(type,'lm'))
        str_selection_s = get(handles.chooseEst_lm, 'String');
        str_selection = str_selection_s{get(handles.chooseEst_lm, 'Value')};
        if ~strcmp(str_selection, '')
            intVars = eval(['handles.c_data.' str_selection]);
            newfields = fieldnames(intVars);
            set(handles.chooseVarName_lm, 'String', newfields);
        end
    end
    if (strcmp(type,'glm'))
        str_selection_s = get(handles.chooseEst_glm, 'String');
        str_selection = str_selection_s{get(handles.chooseEst_glm, 'Value')};
        if ~strcmp(str_selection, '')
            intVars = eval(['handles.c_data.' str_selection]);
            newfields = fieldnames(intVars);
            set(handles.chooseVarName_glm, 'String', newfields);
        end
    end
    

end

