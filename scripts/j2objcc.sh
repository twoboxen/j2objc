#!/bin/bash
# Copyright 2011 Google Inc.  All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# A convenience wrapper for compiling files translated by j2objc using Clang.
# The JRE emulation and proto wrapper library include and library paths are
# added, as well as standard Clang flags for compiling and linking Objective-C
# applications on iOS.
#
# Usage:
#   j2objcc <clang options> <files>
#

if [ -L "$0" ]; then
  readonly DIR=$(dirname $(readlink "$0"))
else
  readonly DIR=$(dirname "$0")
fi

if [ "x${PUBLIC_HEADERS_FOLDER_PATH}" != "x" ]; then
	readonly INCLUDE_PATH=${DIR}/${PUBLIC_HEADERS_FOLDER_PATH}
elif [ -d ${DIR}/include ]; then
  readonly INCLUDE_PATH=${DIR}/include
else
	# Xcode 4 default for new projects.
  readonly INCLUDE_PATH=${DIR}/Headers
fi

declare FRAMEWORKS="-framework Foundation -framework Security"
if [ "x${IPHONEOS_DEPLOYMENT_TARGET}" = "x" ]; then
  FRAMEWORKS="${FRAMEWORKS} -framework ExceptionHandling"
fi

declare CC_FLAGS="-Werror -Wno-parentheses -fno-strict-overflow -Wno-compare-distinct-pointer-types"
declare OBJC="-std=c11"
declare OTHER_LIBS="-l z -l j2objc_main -l c++"
declare SYSROOT_PATH="none"
declare EMUL_LIB="-ljre_emul"
declare LINK_FLAGS=""
declare DO_LINK="yes"
declare CORE_LIB_WARNING="warning: linking the core runtime to reduce binary \
size. Use -ljre_emul to link the full Java runtime."

for arg; do
  case $arg in
    # Check whether linking is disabled by a -c, -S, or -E option.
    -[cSE]) DO_LINK="no" ;;
    # Check whether we need to build for C++ instead of C.
    objective-c\+\+) CC_FLAGS="${CC_FLAGS} -std=c++98" OBJC= ;;
    # Save sysroot path for later inspection.
    -isysroot) SYSROOT_PATH="${i#*=}" ;;
    -ObjC) EMUL_LIB="-ljre_core" ;;
  esac
done

if [[ $@ =~ .*-l(\ )*jre_emul\ .* ]]; then
  EMUL_LIB=""
fi

if [[ "$DO_LINK" == "yes" ]]; then
  if [[ "$SYSROOT_PATH" == "none" || "$SYSROOT_PATH" == *"MacOSX"* ]]; then
    readonly LIB_PATH=${DIR}/lib/macosx
  else
    readonly LIB_PATH=${DIR}/lib
  fi
  if [[ "$EMUL_LIB" == "-ljre_core" ]]; then
    >&2 echo "$CORE_LIB_WARNING";
  fi
  LINK_FLAGS="${EMUL_LIB} ${OTHER_LIBS} ${FRAMEWORKS} -L ${LIB_PATH}"
fi

xcrun clang "$@" -I ${INCLUDE_PATH} ${CC_FLAGS} ${OBJC} ${LINK_FLAGS}
