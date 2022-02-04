# Map Scripts
Useful scripts for Sven Co-op maps

A bunch of trigger_scripts and custom entities for maps that may be useful for map building and conversions

##Instructions:

### trigger_scripts
Follow the included instructions in the top of the script.
For more information on how to use trigger_scripts in your maps, visit https://sites.google.com/site/svenmanor/entguide/trigger_script

###Custom Entities
- Put the script in `scripts/maps`. If you wish to use subfolders, you can but take note of the path
- Create a main script for your map and in your map cfg, add `map_script` followed by the name of the script
- Edit your main script then add this to the top of your main script
```#include "<yourmainscriptname>"```
If your script exists within a subfolder inside `scripts/maps`, then prefix the script name with `<yoursubfoldersname>/` in the `#include` header.
- Create a MapInit function (if it already doesn't exist) and look for a register function in the custom entity script:
```
void MapInit()
{
  RegisterExampleEntity();
}
```
The register function will be named differently in each entity. It should be located at the top of the custom entity script.
If your main script already has stuff inside the MapInit block, simply add the code at the bottom.

### Misc
Some scripts simply just require you add them via `map_script` in map cfg. Again refer to included instructions if unsure.
