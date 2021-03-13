package Ament.Index is

   function Find_Library (Name  : String;
                          Local : Boolean := True)
                          return String;
   --  Find a library installed under its expected "lib<package>__*.so" name.
   --  If not found in its installation place and Local, look for it also under
   --  current directory. (The generator gets called on the same build dir).

   function Find_Package (Name : String) return String;
   --  Finds where a package is installed. This will fail to locate the package
   --  currently being built! Returns "" when not found

end Ament.Index;
