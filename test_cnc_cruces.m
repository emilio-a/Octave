% Programa para hacer una secuencia g-code que dibuje un cuadrado de x ancho por y de alto de crucecitas separadas una 
% distancia d, para hacer testeos de precision y repetitibilidad
% La idea es pintar las crucecitas con una fibra, asi que OJO, usar fibra. Si uso una mecha se romperá

pkg load matgeom; %cargo package, no se si lo tengo que hacer siempre pero...pfff

modo=1; % 0=cruces, 1= espiral cuadrada,
cruces=1;   % dibujo cruces
espiral=0;  % dibujo una espiral
grilla=1;   % dibujo una grilla

origen_x=0; % punto de origen en x
origen_y=0; % punto de origen en y 

z_idle=50;  % altura en mm del eje z en roposo
z_travel=5;   % altura en mm cuando está viajando
z_plunge=-0.1;  %altura a la que se "sumerge"
z_down_feed=20;  % velocidad de bajada
z_up_feed=150;    % velocidad de subida
max_feedrate = 150; % maximo feedrate

%%%%%%%%%%%%%%%% datos para dibijar las cruces #############
x=11; % cantidad de cruces en x
y=11; % cantidad de cruces en y
dx=10; % separacion de las cruces en x en mm
dy=10; % separacion de las cruces en y en mm
hx=1; % ancho de las cruces en x en mm
hy=1; % alto de las cruces en y en mm

############### datos para dibujar cuadrado espiral ##########
x_esp=100;  % ancho del cuadrado en mm
y_esp=100;  % altura del cuadrado en mm
dx_esp=10;   % paso del espiral en x
dy_esp=10;   % paso del espiral en y
radio_stop = 2; % cuando el espiral este a menos de este punto del final, se detiene


% condiciones iniciales
punto_x=origen_x;
punto_y=origen_y;

filename = "/home/emilio/Documentos/prueba_cnc.txt";  %nombre del archivo GCODE a crear
fid = fopen (filename, "w");  % creo file en modo escritura
fputs (fid, "( Archivo de prueba para dibujar cruces en un CNC )\n");  % saco string
fputs (fid, "( Creado el ");  % saco string
fputs (fid, strftime ("%Y-%m-%d %H:%M:%S )", localtime (time ())));  %imprimo la fecha

fputs(fid,"\n\n");  % hago espacio

fputs (fid, "G21\n"); % todas las unidades en mm
fputs (fid, "G90\n"); % distancia absoluta (no relativa)
fputs (fid, "G94\n\n"); % unidades por minuto, feed speed

fprintf (fid, "G01 F%3.4f\n\n", max_feedrate); % interpolacion lineal, con este maximo feed rate

fputs (fid, "G00");  % Posiciona al maximo feedrate
fprintf(fid, "Z%3.4f\n", z_idle); %muevo punta hasta la posicion de reposo
fprintf(fid, "X%3.4f Y%3.4f\n",origen_x,origen_y); %muevo punta hasta el origen
fprintf(fid, "Z%3.4f\n", z_travel); %muevo punta hasta la posicion de travel

if (cruces!=0) % lazo central para hacer cruces
    direccion_x=1;
    for pasos_y=1:y
      for pasos_x=1:x
          fprintf(fid, "G00 X%3.4f Y%3.4f\n",punto_x-hx,punto_y+hy);    % ubico punta en punto_x - hx, punto_y+hy 
          fprintf(fid, "G00 Z%3.4f F%3.4f\n", z_plunge,z_down_feed);    % bajo punta hasta z_plunge
          fprintf(fid, "G01 X%3.4f Y%3.4f\n",punto_x+hx,punto_y-hy);    % muevo punta hasta punto_x + hx, punto_y - hy
          fprintf(fid, "G00 Z%3.4f F%3.4f\n", z_travel, z_up_feed);     % subo punta hasta z_travel
          fprintf(fid, "G00 X%3.4f Y%3.4f\n",punto_x-hx,punto_y-hy);    % muevo punta hasta punto_x-hx, punto_y-hy
          fprintf(fid, "G00 Z%3.4f F%3.4f\n", z_plunge, z_down_feed);   % bajo punta hasta z_plunge
          fprintf(fid, "G01 X%3.4f Y%3.4f\n",punto_x+hx,punto_y+hy);    % muevo punta hasta punto_x+hx, punto_y+hy
          fprintf(fid, "G00 Z%3.4f F%3.4f\n", z_travel, z_up_feed);     % subo punta hasta z_travel
          punto_x = punto_x + direccion*dx;  
      endfor
        if(direccion==1) direccion=-1;
        else direccion=1;
        %punto_x = origen_x;
        punto_y = punto_y - dy;
    endfor
    fprintf(fid, "G00 Z%3.4f F%3.4f\n", z_idle, z_up_feed);     % subo punta hasta z_travel
endif
if (espiral!=0) %ejecuto codigo para cuadrado espiral
    limite=[(x_esp-origen_x)/2,-(y_esp-origen_y)/2, radio_stop]; % defino un circulo, x,y, radio
    esquina_ul=[origen_x+dx_esp, origen_y-dy_esp];
    esquina_ur=[ x_esp , origen_y];
    esquina_dr=[ x_esp, -y_esp];
    esquina_dl=[origen_x+dx, -y_esp];
    fprintf(fid, "Z%3.4f\n", z_idle); %muevo punta hasta la posicion de reposo
    fprintf(fid, "G00 X%3.4f Y%3.4f\n", origen_x, origen_y);  %
    fprintf(fid, "G01 Z%3.4f F%3.4f\n", z_plunge,z_down_feed);    % bajo punta hasta z_plunge
  while ( (!isPointInCircle(esquina_ul,limite) && !isPointInCircle(esquina_ur,limite)) && (!isPointInCircle(esquina_dr,limite) && !isPointInCircle(esquina_dl,limite))); 
    
    fprintf(fid, "G01 X%3.4f Y%3.4f\n", esquina_ur(1),esquina_ur(2));  %  test
    fprintf(fid, "G01 X%3.4f Y%3.4f\n", esquina_dr(1),esquina_dr(2));  %
    fprintf(fid, "G01 X%3.4f Y%3.4f\n", esquina_dl(1),esquina_dl(2));  %
    fprintf(fid, "G01 X%3.4f Y%3.4f\n", esquina_ul(1),esquina_ul(2));  %
    esquina_ul += [ dx_esp,-dy_esp];
    esquina_ur += [-dx_esp,-dy_esp];
    esquina_dr += [-dx_esp, dy_esp];
    esquina_dl += [ dx_esp, dy_esp];
  
  endwhile
    fprintf(fid, "G00 Z%3.4f F%3.4f\n", z_idle, z_up_feed);     % subo punta hasta z_travel
endif

if(grilla !=0)
          punto_x=origen_x;
          punto_y=origen_y;
      for pasos_x=1:x
          fprintf(fid, "G00 X%3.4f Y%3.4f\n",punto_x,punto_y);      % ubico punta en punto_x - hx, punto_y+hy 
          fprintf(fid, "G00 Z%3.4f F%3.4f\n", z_plunge,z_down_feed);    % bajo punta hasta z_plunge
          fprintf(fid, "G01 X%3.4f Y%3.4f\n",punto_x,-dy*y);        % muevo punta hasta punto_x + hx, punto_y - hy
          fprintf(fid, "G00 Z%3.4f F%3.4f\n", z_travel, z_up_feed);     % subo punta hasta z_travel
          punto_x = punto_x + dx;  
      endfor
          fprintf(fid, "G00 Z%3.4f F%3.4f\n", z_idle, z_up_feed);     % subo punta hasta z_idle
          punto_x=origen_x;
          punto_y=origen_y;
      for pasos_y=1:y
          fprintf(fid, "G00 X%3.4f Y%3.4f\n",punto_x,punto_y);        % muevo punta hasta punto_x-hx, punto_y-hy
          fprintf(fid, "G00 Z%3.4f F%3.4f\n", z_plunge, z_down_feed);   % bajo punta hasta z_plunge
          fprintf(fid, "G01 X%3.4f Y%3.4f\n", dx*x,punto_y);          % muevo punta hasta punto_x+hx, punto_y+hy
          fprintf(fid, "G00 Z%3.4f F%3.4f\n", z_travel, z_up_feed);     % subo punta hasta z_travel
        punto_y = punto_y - dy;
      endfor
      fprintf(fid, "G00 Z%3.4f F%3.4f\n", z_idle, z_up_feed);     % subo punta hasta z_idle
endif

fputs(fid,"M05\n"); % spindle control
fprintf(fid, "G00 Z%3.4f\n", z_idle); % muevo punta hasta la posicion de reposo
fprintf(fid, "G00 X%3.4f Y%3.4f\n",origen_x,origen_y); %muevo punta hasta el origen
fputs(fid,"M02\n"); % program pause and end

fclose (fid); % cierro file
clear;  % limpio todas las variables