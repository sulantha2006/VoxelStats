function chooseVariable(hObject,eventdata, type)
handles = guidata(hObject);
    if (strcmp(type,'lm'))
        str_selection = get(handles.chooseEst_lm, 'Value');
        newfields = fieldnames(handles.c_data(str_selection));
        set(handles.chooseVarName_lm, 'String', newfields);
    end
    if (strcmp(type,'glm'))
        str_selection = get(handles.chooseEst_glm, 'Value');
        newfields = fieldnames(handles.c_data(str_selection));
        set(handles.chooseVarName_glm, 'String', newfields);
    end
    

end

