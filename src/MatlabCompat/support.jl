module Support
# this module contains supporting functions used by MatlabCompat library
  using Images
  using ImageView


  function mat2im(array)
    image = grayim(array)
    return image
  end

  function im2mat(image)
    array = reinterpret(Float32, float32(image))
    return array
  end

  # an m-file parser aimed at converting them as close as possible from MATLAB syntax to Julia syntax
  #using
  function rossetta(inputMfilePath, outputJlFilePath)
    # read the m-file
    mFileContents = open(readlines, inputMfilePath)

    # here we parse the MATLAB/Octave code to be compatible with Julia through MatlabCompat library
    mFileContentsParsed = mFileContents;

  for iLine = 1:size(mFileContents,1)
      # 1. substitute % by # excluding
      if ismatch(r"^(\t*|\s*)%.*", mFileContents[iLine])
        # 1a. match the simplest case when % is in the beginning of the line with any number of white spaces or tabs. If true replace the first occurance of %
        mFileContentsParsed[iLine] = replace(mFileContents[iLine], "%", "#", 1)
      elseif ismatch(r".*\'.*", mFileContents[iLine]) && ismatch(r".*%.*", mFileContents[iLine])
        # 1b. match a complex case where % may be inside of the single quotes - this % shouldn't be replaced
        println("\' and % present");
        fragmentedString = split(mFileContents[iLine], "%")
        numberOfQuotes = 0
        fragmentToComment = 0
        newLine = ""
        firstOccurance = true
        for iFragment = 1:length(fragmentedString)
          # count the quotes
          if ismatch(r"\'", fragmentedString[iFragment])
            numberOfQuotes = numberOfQuotes + length(matchall(r"\'", fragmentedString[iFragment]))
          end
          # if number of quotes is even - they are closed, we can exchange the first occurance of % with # safely
          if (iseven(numberOfQuotes) && numberOfQuotes != 0 && firstOccurance == true)
            newLine = string(newLine, fragmentedString[iFragment], "#");
            firstOccurance = false;
          # is it last fragment?
          elseif (iFragment == length(fragmentedString))
            newLine = string(newLine, fragmentedString[iFragment]);
          else
            newLine = string(newLine, fragmentedString[iFragment], "%");
          end
        end
        mFileContentsParsed[iLine] = newLine
      elseif ~ismatch(r".*\'.*", mFileContents[iLine]) && ismatch(r".*%.*", mFileContents[iLine])
        # 1c. match a case where only % symbols are present
        println("% present");
        mFileContentsParsed[iLine] = replace(mFileContents[iLine], "%", "#")
      else
        println("no comment detected");
        mFileContentsParsed[iLine] = mFileContents[iLine];
      end
      # 2. substitute all single quotes ' by double quotes "
      if ismatch(r".*\'.*", mFileContentsParsed[iLine])
        mFileContentsParsed[iLine] = replace(mFileContentsParsed[iLine], "\'", "\"");
      end
   end
    # 3. append the code array with "using ..."

    extraLines = ["#This Julia file has been generated by rossetta script of MatlabCompat library from an m-file\n\r";
                "#The code generated need further corrections by you. Execute it line by line and correct the errors.\n\r";
                "using MatlabCompat\n\r using MatlabCompat.ImageTools:imread\n\r using MatlabCompat.MathTools:max\n\r using MatlabCompat.ImageTools.Morph\n\r"];
    mFileContentsParsed = vcat(extraLines,mFileContentsParsed)

    # write the jl-file
     jlFileStream = open(outputJlFilePath, "w")
     write(jlFileStream, mFileContentsParsed);
     close(jlFileStream);
    return mFileContentsParsed;
  end


end #End of Support
