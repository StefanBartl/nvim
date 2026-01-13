-- ---@class neotree.Preview.Config
-- ---@field use_float boolean?
-- ---@field use_image_nvim boolean?
-- ---@field use_snacks_image boolean?

-- ---@class neotree.Preview.Event
-- ---@field source string?
-- ---@field event neotree.event.Handler

-- ---@class neotree.Preview
-- ---@field config neotree.Preview.Config?
-- ---@field active boolean Whether the preview is active.
-- ---@field winid integer The id of the window being used to preview.
-- ---@field is_neo_tree_window boolean Whether the preview window belongs to neo-tree.
-- ---@field bufnr number The buffer that is currently in the preview window.
-- ---@field start_pos integer[]? An array-like table specifying the (0-indexed) starting position of the previewed text.
-- ---@field end_pos integer[]? An array-like table specifying the (0-indexed) ending position of the preview text.
-- ---@field truth table A table containing information to be restored when the preview ends.
-- ---@field events neotree.Preview.Event[] A list of events the preview is subscribed to.
-- local Preview = {}
