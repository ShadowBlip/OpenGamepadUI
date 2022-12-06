#include "pythonscript.h"
#include "godot_cpp/classes/file_access.hpp"
#include "godot_cpp/classes/global_constants.hpp"
#include "godot_cpp/variant/array.hpp"
#include "godot_cpp/variant/string.hpp"
#include <python3.10/Python.h>
#include <python3.10/import.h>
#include <python3.10/object.h>
#include <python3.10/pylifecycle.h>
#include <python3.10/unicodeobject.h>

using namespace godot;

PythonScript::PythonScript() {
  // Initialize the python interface
  Py_Initialize();
};
PythonScript::~PythonScript() {
  // Close the python instance
  Py_Finalize();
};

// Run the given script text
// https://medium.datadriveninvestor.com/how-to-quickly-embed-python-in-your-c-application-23c19694813
void PythonScript::run_script(String code, Array output) {
  // Initialize the python interface
  Py_Initialize();

  // Create main module
  PyObject *pModule = PyImport_AddModule("__main__");

  // Invoke code to redirect output
  const char *stdOut = "import sys\n\
class CatchOut:\n\
  def __init__(self):\n\
    self.value = ''\n\
  def write(self, txt):\n\
    self.value += txt\n\
catchOut = CatchOut()\n\
sys.stdout = catchOut\n\
sys.stderr = catchOut\n"; // this is python code to redirect stdouts/stderr
  PyRun_SimpleString(stdOut);

  // Run the input code
  int ret = PyRun_SimpleStringFlags(code.ascii().get_data(), __null);

  // Get the reference to the python redirect object
  PyObject *catcher = PyObject_GetAttrString(pModule, "catchOut");
  PyObject *out = PyObject_GetAttrString(catcher, "output");

  String data = String(PyUnicode_AsUTF8(out));

  // Append our output array with the script output
  output.append(data);

  // Close the python instance
  Py_Finalize();
};

// Runs the given python script file
int PythonScript::run_file(const String path) {
  // Ensure the given file exists
  if (!FileAccess::file_exists(path)) {
    return ERR_FILE_BAD_PATH;
  }

  // Initialize the python interface
  Py_Initialize();

  // Read the file
  Ref<FileAccess> file = FileAccess::open(path, FileAccess::ModeFlags::READ);
  String text = file->get_as_text();

  // Run a simple string
  int ret = PyRun_SimpleStringFlags(text.ascii().get_data(), __null);

  // Close the python instance
  Py_Finalize();

  return OK;
};

// Register the methods with Godot
void PythonScript::_bind_methods() {
  ClassDB::bind_static_method("PythonScript",
                              D_METHOD("run_script", "code", "output"),
                              &PythonScript::run_script);
  ClassDB::bind_static_method("PythonScript", D_METHOD("run_file", "path"),
                              &PythonScript::run_file);
};
