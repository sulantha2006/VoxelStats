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
    if (strcmp(type,'roc'))
        str_selection_s = get(handles.chooseEst_roc, 'String');
        str_selection = str_selection_s{get(handles.chooseEst_roc, 'Value')};
        if ~strcmp(str_selection, '')
            intVars = eval(['handles.c_data.' str_selection]);
            %newfields = fieldnames(intVars);
            %set(handles.chooseVarName_roc, 'String', newfields);
        end
    end
    if (strcmp(type,'t'))
        str_selection_s = get(handles.chooseEst_t, 'String');
        str_selection = str_selection_s{get(handles.chooseEst_t, 'Value')};
        if ~strcmp(str_selection, '')
            intVars = eval(['handles.c_data.' str_selection]);
            newfields = fieldnames(intVars);
            set(handles.chooseVarName_t, 'String', newfields);
        end
    end
    if (strcmp(type,'pt'))
        str_selection_s = get(handles.chooseEst_pt, 'String');
        str_selection = str_selection_s{get(handles.chooseEst_pt, 'Value')};
        if ~strcmp(str_selection, '')
            intVars = eval(['handles.c_data.' str_selection]);
            newfields = fieldnames(intVars);
            set(handles.chooseVarName_pt, 'String', newfields);
        end
    end
end

