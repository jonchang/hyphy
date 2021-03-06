#!/bin/sh


TARGET_NAME="DEV_GUI"
LIBRARY_BINDINGS="NONE"

	
COMPILER="g++.exe";
COMPILERC="gcc.exe";
RC_COMPILER="windres.exe"

COMPILER_FLAGS=" -D __WINDOZE__ -w -c -fsigned-char -O3 -fpermissive -I`pwd`/Source -I`pwd`/Source/SQLite -I`pwd`/Win32GUI -D INTPTR_TYPE=long "	

echo "Checking for curl";

rm -rf curl_check*

(echo "#include <curl/curl.h>"; echo "int main(void) {return 0;}") | cat - > curl_check.cpp

if `$COMPILER -o curl_check -w $CURL_LINKER_LIBS curl_check.cpp`
then
 echo "Curl seems to be present"
else
	echo "Curl seems to be absent (setting up compiler options skip CURL code)";
	CURL_LINKER_LIBS="";
	COMPILER_FLAGS=$COMPILER_FLAGS" -D__HYPHY_NO_CURL__";
	COMPILER_LINK_FLAGS=$COMPILER_LINK_FLAGS" -D__HYPHY_NO_CURL__";
fi

rm -rf curl_check*

	
makedir () {
	if [ -f $1 ] 
	then
		echo "Insufficient permissions to create an object directory";
		exit 1;
	fi
	
	if [ ! -d $1  ]
	then
		if [ `mkdir $1` ]
		then
			echo "Failed to create directory $1";
			exit 1;
		fi
	fi
}

OBJ_DIR_NAME="obj_$TARGET_NAME"

if [ -f $OBJ_DIR_NAME ] 
then
	rm -rf $OBJ_DIR_NAME;
fi

makedir $OBJ_DIR_NAME


TARGET_NAME="HYPHYMP_Win32.exe";
LINKER_FLAGS=$CURL_LINKER_LIBS" -D WINVER=0x0500 -lgomp -lpthread -lcomctl32 -lwinspool -lwininet -lmsimg32 -mwindows ";
echo "+-----------------------------------------------------------+"
echo "|Building a OpenMP/MigGW/Win32 dev.       version of HyPhy  |"
echo "+-----------------------------------------------------------+"
COMPILER_FLAGS=$COMPILER_FLAGS" -D __MP__ -D __MP2__ -D _SLKP_LFENGINE_REWRITE_ -fopenmp -D WINVER=0x0500 -mwindows  "

echo "COMPILER_FLAGS = "$COMPILER_FLAGS
echo "LINKER_FLAGS   = "$LINKER_FLAGS

cd Source 

for fileName in *.cpp main-win.cxx
do
  if [ ${fileName} != "hyphyunixutils.cpp" ]
  then
	  obj_file=../$OBJ_DIR_NAME/${fileName}.o;
	  if [ $obj_file -nt $fileName ]
	  then
		echo File "$fileName" is up to date
	  else
		  echo Building "$fileName";
		  if `$COMPILER -o $obj_file $COMPILER_FLAGS $fileName `
		   then
			 echo Complete
		   else
				echo Error during compilation;
				exit 1;
		   fi
	  fi
  fi
done

cd SQLite

for fileName in *.c
do
  obj_file=../../$OBJ_DIR_NAME/${fileName}.o;
  if [ $obj_file -nt $fileName ]
  then 
  	echo SQLite File "$fileName" is up to date
  else
	  echo Building "SQLite file $fileName";
	  if `$COMPILERC -o $obj_file $COMPILER_FLAGS $fileName `
	   then
	                echo Complete
	   else
	                echo Error during compilation;
	                exit 1;
	   fi
  fi
done

cd ../../Win32GUI

for fileName in *.cpp
do
  obj_file=../$OBJ_DIR_NAME/${fileName}.o;
  if [ $obj_file -nt $fileName ]
  then
	echo File "$fileName" is up to date
  else
	  echo Building "$fileName";
	  if `$COMPILER -o $obj_file $COMPILER_FLAGS $fileName `
	   then
		 echo Complete
	   else
			echo Error during compilation;
			exit 1;
	   fi
  fi
done

cd Windows

for fileName in *.rc
do
  obj_file=../../$OBJ_DIR_NAME/${fileName}.o;
  if [ $obj_file -nt $fileName ]
  then
	echo File "$fileName" is up to date
  else
	  echo Building "$fileName";
	  if `$RC_COMPILER -o $obj_file $fileName `
	   then
		 echo Complete
	   else
			echo Error during compilation;
			exit 1;
	   fi
  fi
done


cd ../../

echo Linking $TARGET_NAME
echo $COMPILER $COMPILER_LINK_FLAGS -o $TARGET_NAME $OBJ_DIR_NAME/*.o  $LINKER_FLAGS
`$COMPILER $COMPILER_LINK_FLAGS -o $TARGET_NAME $OBJ_DIR_NAME/*.o  $LINKER_FLAGS`

echo Finished


