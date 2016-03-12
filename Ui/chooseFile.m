function [ dirName, fileName ] = chooseFile(hObject,eventdata,textField)
  [fileName, dirName] = uigetfile({'*.*'}, 'File Selector');
  if fileName
    fullPath = [dirName fileName];
    set(textField, 'String', fullPath);
  end
end

