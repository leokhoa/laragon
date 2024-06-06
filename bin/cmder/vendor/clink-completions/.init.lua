-- The line below extends package.path with modules
-- directory to allow to require them
package.path = debug.getinfo(1, "S").source:match[[^@?(.*[\/])[^\/]-$]] .."modules/?.lua;".. package.path