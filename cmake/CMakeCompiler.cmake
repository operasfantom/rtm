cmake_minimum_required (VERSION 3.2)

macro(setup_default_compiler_flags _project_name)
	if(MSVC) # That's also clang-cl
		# Replace some default compiler switches and add new ones
		STRING(REPLACE "/GR" "" CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS})			# Disable RTTI
		STRING(REPLACE "/W3" "/W4" CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS})		# Bump warnings to W4
		target_compile_options(${_project_name} PRIVATE /Zi)				# Add debug info
		target_compile_options(${_project_name} PRIVATE /Oi)				# Generate intrinsic functions
		target_compile_options(${_project_name} PRIVATE /WX)				# Treat warnings as errors
		if (CMAKE_CXX_COMPILER_ID MATCHES "MSVC") # no Clang no Intel
			target_compile_options(${_project_name} PRIVATE /MP)            # Enable parallel compilation
		endif ()

		if(MSVC_VERSION GREATER 1900)
			# VS2017 and above
			target_compile_options(${_project_name} PRIVATE /permissive-)
		endif()

		if(USE_SIMD_INSTRUCTIONS)
			if(USE_AVX2_INSTRUCTIONS)
				target_compile_options(${_project_name} PRIVATE "/arch:AVX2")
			elseif(USE_AVX_INSTRUCTIONS)
				target_compile_options(${_project_name} PRIVATE "/arch:AVX")
			endif()
		else()
			add_definitions(-DRTM_NO_INTRINSICS)
		endif()

		# Add linker flags
		set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /DEBUG")
	else()
		# TODO: Handle OS X properly: https://stackoverflow.com/questions/5334095/cmake-multiarchitecture-compilation
		if(CPU_INSTRUCTION_SET MATCHES "x86")
			target_compile_options(${_project_name} PRIVATE "-m32")
			target_link_libraries(${_project_name} PRIVATE "-m32")
		elseif(CPU_INSTRUCTION_SET MATCHES "x64")
			target_compile_options(${_project_name} PRIVATE "-m64")
			target_link_libraries(${_project_name} PRIVATE "-m64")
		endif()

		if(CPU_INSTRUCTION_SET MATCHES "x86" OR CPU_INSTRUCTION_SET MATCHES "x64")
			if(USE_SIMD_INSTRUCTIONS)
				if(USE_AVX2_INSTRUCTIONS)
					target_compile_options(${_project_name} PRIVATE "-mavx2")
					target_compile_options(${_project_name} PRIVATE "-mavx")
					target_compile_options(${_project_name} PRIVATE "-mbmi")
					target_compile_options(${_project_name} PRIVATE "-mfma")
				elseif(USE_AVX_INSTRUCTIONS)
					target_compile_options(${_project_name} PRIVATE "-mavx")
					target_compile_options(${_project_name} PRIVATE "-mbmi")
				else()
					target_compile_options(${_project_name} PRIVATE "-msse4.1")
				endif()
			else()
				add_definitions(-DRTM_NO_INTRINSICS)
			endif()
		endif()

		target_compile_options(${_project_name} PRIVATE -Wall -Wextra)		# Enable all warnings
		target_compile_options(${_project_name} PRIVATE -Wshadow)			# Enable shadowing warnings
		target_compile_options(${_project_name} PRIVATE -Werror)			# Treat warnings as errors

		target_compile_options(${_project_name} PRIVATE -g)					# Enable debug symbols
	endif()
endmacro()
