import { useBackend, useLocalState } from '../backend';
import { Box, Tooltip, Icon, Stack } from '../components';
import { Window } from '../layouts';
import { Object } from './Map.js';
import { Component } from 'inferno';

export class Minimap extends Component {
  constructor() {
    super();
    this.state = {
      selectedName: null,
    };
  }

  globalToLocal(background_loc, coord) {
    const { data } = useBackend(this.context);
    const {
      icon_size,
      player_viewsize = 36,
    } = data;
    const newCoord = [];
    newCoord[0] = (coord[0])*icon_size + background_loc[0];
    newCoord[1] = ((map_size_tile_y-coord[1])*icon_size) + background_loc[1];

    if (newCoord[0] < 0 || newCoord[0] > icon_size*player_viewsize
      || newCoord[1] < 0 || newCoord[1] > icon_size*player_viewsize) {
      return null;
    }
    return newCoord;
  };

  render() {
    const { data } = useBackend(this.context);
    const {
      map_name,
      map_size_x,
      map_size_y,
      icon_size,
      coord_data,
      player_coord,
      player_ref,
      player_viewsize = 36,
    } = data;
    const {
      selectedName
    } = this.state;

    const minimapPadding = 10;

    const map_size_tile_x = (map_size_x/icon_size);
    const map_size_tile_y = (map_size_y/icon_size);

    const view_offset = player_viewsize/2;

    let background_loc = [
      Math.max(
        Math.min(0, -(player_coord[0]-view_offset)*icon_size),
        -(map_size_tile_x-player_viewsize)*icon_size
      ),
      Math.max(
        Math.min(0, -(map_size_tile_y-player_coord[1]-view_offset)*icon_size),
        -(map_size_tile_y-player_viewsize)*icon_size
      ),
    ];

    return (
      <Window
        width={icon_size*player_viewsize + minimapPadding*2}
        height={icon_size*player_viewsize + minimapPadding*2 + 30}
        theme="engi"
      >
        <Window.Content id="minimap">
          <Stack>
            <Stack.Item>
              <Box
                className="Minimap__Map"
                style={{
                  'background-image': `url('minimap.${map_name}.png')`,
                  'background-repeat': "no-repeat",
                  'background-position-x': `${background_loc[0]}px`,
                  'background-position-y': `${background_loc[1]}px`,
                  'width': `${icon_size*player_viewsize}px`,
                  'height': `${icon_size*player_viewsize}px`,
                }}
                position="absolute"
                left={`${minimapPadding}px`}
                top={`${minimapPadding}px`}
                onMouseDown={() => this.setState({ selectedName: null })}
              >
                {coord_data.map(val => {
                  let object_coord = val.coord;
                  if (val.ref === player_ref) object_coord = player_coord;
                  const local_coord = this.globalToLocal(background_loc, object_coord);
                  if (!local_coord) return;
                  return (
                    <Object
                      key={val.ref}
                      name={val.name}
                      opacity={!selectedName
                        || selectedName === val.ref? 1 : 0.5}
                      selected={selectedName === val.ref}
                      onMouseDown={e => {
                        this.setState({ selectedName: val.ref });
                        e.stopPropagation();
                      }}
                      coord={local_coord}
                      icon={val.icon}
                      color={val.color}
                      obj_ref={val.ref}
                      obj_width={val.width}
                      obj_height={val.height}
                    />
                  );
                })}
              </Box>
            </Stack.Item>
          </Stack>
        </Window.Content>
      </Window>
    );
  }
}
