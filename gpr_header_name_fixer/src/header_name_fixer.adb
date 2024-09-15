with Ada.Command_Line; use Ada.Command_Line;
with Ada.Directories;  use Ada.Directories;
with Ada.Text_IO; use Ada.Text_IO;

procedure Header_Name_Fixer is

   function Fix (Name : String) return String;

   ---------
   -- Fix --
   ---------

   function Fix (Name : String) return String is
   begin
      if Name'First /= 1 then
         raise Program_Error with "Expected 1-based indexing";
      end if;

      for I in 1 .. Name'Last loop
         if Name (1 .. I) & Name (1 .. I) & Name (I * 2 + 1 .. Name'Last) =
           Name
         then
            return Name (Name'First .. I) & Name (I * 2 + 1 .. Name'Last);
         end if;
      end loop;

      return Name;
   end Fix;

   Dir  : Search_Type;
   File : Directory_Entry_Type;
begin
   Put_Line ("Fixing file names in folder " & Full_Name (Argument (1)));
   Start_Search (Dir, Argument (1), "*.ads");

   while More_Entries (Dir) loop
      Get_Next_Entry (Dir, File);

      declare
         Parent    : constant String := Containing_Directory (Full_Name (File));
         Orig_Name : constant String := Simple_Name (File);
         New_Name  : constant String := Fix (Orig_Name);
      begin
         if New_Name /= Orig_Name then
            Put_Line ("   Ada fixing: " & Orig_Name & " --> " & New_Name);
            Rename (Compose (Parent, Orig_Name), Compose (Parent, New_Name));
         end if;
      end;
   end loop;

   End_Search (Dir);
end Header_Name_Fixer;
