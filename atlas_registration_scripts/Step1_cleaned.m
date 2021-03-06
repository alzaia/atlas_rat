%--------------------------------------------------------------------------
% Name: step1_preprocessing.m
% Date: 2017/11/23
% Description: Step 1: Preprocessing: Estimate a 2D rigid transformation
% in order to put the original maps into a common space, centered at Label 
% #1 and oriented such that the line defined by Label #1 and Label #2
% is vertical. Apply transformation to axon density map. Loop across 
% subjects and levels.
%--------------------------------------------------------------------------

list_levels = sct_tools_ls('*'); % get names of level folders

% loop over levels
for ii=1:length(list_levels)
    
    cd(char(list_levels(ii)));
    list_samples = sct_tools_ls('*'); % get names of sample folders
    
    % loop over samples
    for jj=1:length(list_samples)
        
        % load labels #1 and #2 from step0 output
        cd(char(list_samples(jj)));
        load('Label1');
        load('Label2');
        x1=Label1(1);
        y1=Label1(2);
        x2=Label2(1);
        y2=Label2(2);

        PixelSize=0.05; 

        % find right orientation of the rotation
        name=[ char(list_samples(jj)) '_mask.nii.gz'];
        img=load_nii_data(name);
        sizey=size(img,2);

        ym=(sizey-1)/2;
        line_eq = ym;

        if y2>=ym
            y2=-y2;
        end

        % find the translation

        xref1=76;
        yref1=76;

        dx=xref1-x1;
        dy=yref1-y1;
        Translation_Matrix = [1 0 0; 0 1 0; dx dy 1];

        % find the rotation

        A=[0;0]; 
        B=[0;1];
        u= A-B;
        x_u=u(1);
        y_u=u(2);

        C=[x1;y1]; 
        D=[x2;-y2];
        v=D-C;
        x_v=v(1);
        y_v=v(2);

        theta_deg=radtodeg(atan2(x_u*y_v-x_v*y_u,x_u*x_v+y_u*y_v));
        Rotation_Matrix= [cosd(theta_deg) sind(theta_deg) 0;-sind(theta_deg) cosd(theta_deg) 0;0 0 1];

        Transfo_Matrix=Rotation_Matrix;
        Transfo_Matrix(1,3)=dx*PixelSize;
        Transfo_Matrix(2,3)=dy*PixelSize;
        
        % write the full rigid transformation into a text file
        Ants_writeaffinetransfo(Transfo_Matrix);

        % Apply the rigid transformation on the image using ANTs
        sct_unix(['isct_antsApplyTransforms -d 2 -i ' char(list_samples(jj)) '_mask_reg.nii.gz -o ' char(list_samples(jj)) '_mask_reg_reg.nii.gz -t affine_transfo.txt -r ref_template_50um_' char(list_samples(jj)) '.nii.gz']);

        % correct symmetry if not respected
        name1=[char(list_samples(jj)) '_mask_reg_reg.nii.gz'];
        img_to_rotate=load_nii_data(name1);
%         a=regionprops(im2bw(img),'Orientation','Centroid');
%         if size(a,1)>1
%             disp('<strong> ERROR: *** The mask of current sample has more than 1 connected component! *** </strong>'); 
%         end
%         img_sym=imrotate(img_to_rotate,90-(a.Orientation),'bilinear','crop');
%         img_sym=im2bw(img_sym);
         name2=[char(list_samples(jj)) '_mask_reg_reg.nii.gz'];
%         save_nii_v2(img_sym,name2,name1,16);
%         clear a
        cd ..
        
        % add flips for template input
        name3=[char(list_samples(jj)) 'flip'];
        mkdir(name3);
        
        img_flip= flip(img_to_rotate);
        
        cd(name3);
        copyfile(['../' char(list_samples(jj)) '/' char(list_samples(jj)) '_mask_reg_reg.nii.gz']); 

        name4=[char(list_samples(jj)) 'flip' '_mask_reg_reg.nii.gz'];
        save_nii_v2(img_flip,name4, name2,16);
        
        delete(name2);
        cd ..
        
    end  
    cd .. 
end


