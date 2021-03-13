with AAA.Strings;
with Ada.Directories;
with C_Strings;

package body Ament.Index is

   ------------------
   -- Find_Package --
   ------------------

   function Find_Package (Name : String) return String
   is
      function Query (Pack : C_Strings.Chars_Ptr) return C_Strings.Chars_Ptr
        with Import, Convention => C,
        External_Name => "rosidl_ada_find_package_install_path";
   begin
      return
        C_Strings.Value (Query (C_Strings.To_C (Name).To_Ptr), Free => True);
   end Find_Package;

   ------------------
   -- Find_Library --
   ------------------

   function Find_Library (Name  : String;
                          Local : Boolean := True)
                          return String
   is
      use AAA.Strings;
      use Ada.Directories;

      Pack   : constant String := Tail (Head (Name, "__"), "lib");
      Prefix : constant String := Find_Package (Pack);
      Cwd    : constant String := Current_Directory;
   begin
      if Prefix /= "" then
         if Exists (Prefix & "/lib/" & Name) then
            return Prefix & "/lib/" & Name;
         end if;
      end if;

      if Local and then Exists (Compose (Cwd, Name)) then
         return Compose (Cwd, Name);
      end if;

      return "";
   end Find_Library;

end Ament.Index;
